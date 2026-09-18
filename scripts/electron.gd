extends Node2D
class_name Electron
signal death_animation_finished
signal level_completed
signal size_changed(size: int)
@export var start_delay: float = 1.00
@export var spawn_flash_time: float = 0.09
@export var death_flash_time: float = 0.08
@export var speed: float = 180.0
const SOURCE_SIZE := 32.0

const ELECTRON_THIN := [
	preload("res://art/electrons/thin1.png"),
	preload("res://art/electrons/thin2.png"),
	preload("res://art/electrons/thin3.png"),
]

const ELECTRON_NORMAL := [
	preload("res://art/electrons/norm1.png"),
	preload("res://art/electrons/norm2.png"),
	preload("res://art/electrons/norm3.png"),
]

const ELECTRON_THICK := [
	preload("res://art/electrons/thick1.png"),
	preload("res://art/electrons/thick2.png"),
	preload("res://art/electrons/thick3.png"),
]

var sprite: AnimatedSprite2D
var board: CircuitBoard
var settings: GameSettings

var previous_cell := Vector2i.ZERO
var current_cell := Vector2i.ZERO
var next_cell := Vector2i.ZERO
var buffered_direction := Vector2i.ZERO

var current_size: int = 1
var progress := 0.0

enum State {
	STARTING,
	MOVING,
	WAITING_FOR_CHOICE,
	DYING,
	FINISHED
}
var state: State = State.STARTING

var junction_options: Array[Vector2i] = []

func _ready() -> void:
	create_sprite()

func setup(new_board: CircuitBoard, new_settings: GameSettings) -> void:
	board = new_board
	settings = new_settings
	
	current_cell = board.level.start_cell
	previous_cell = current_cell
	
	current_size = board.level.start_electron_size
	size_changed.emit(current_size)
	
	match settings.difficulty:
		GameSettings.Difficulty.EASY:
			speed = settings.easy_speed

		GameSettings.Difficulty.MEDIUM:
			speed = settings.medium_speed

		GameSettings.Difficulty.HARD:
			speed = settings.hard_speed
	
	global_position = board.grid_to_global(current_cell)
	
	var art_scale := board.level.cell_size / SOURCE_SIZE
	sprite.scale = Vector2.ONE * art_scale

	update_electron_sprite()

	var neighbors: Array[Vector2i] = board.get_neighbors(current_cell)

	if neighbors.is_empty():
		push_error("Start cell has no connected wire")
		return
	
	var first_cell: Vector2i = neighbors[0]
	
	if !board.can_traverse(current_cell, first_cell, current_size):
		hit_blocked_wire(first_cell)
		return
	
	
	set_next_cell(first_cell)
	progress = 0.0
	state = State.STARTING
	start_seq()
	

func start_seq() -> void:
	state = State.STARTING
	sprite.visible = false
	
	# a small animation
	AudioManager.play_countdown()
	await get_tree().create_timer(0.15).timeout
	sprite.visible = true
	await get_tree().create_timer(spawn_flash_time).timeout
	sprite.visible = false
	await get_tree().create_timer(spawn_flash_time).timeout
	sprite.visible = true
	await get_tree().create_timer(spawn_flash_time * 1.4).timeout
	sprite.visible = false
	await get_tree().create_timer(spawn_flash_time).timeout
	sprite.visible = true
	await get_tree().create_timer(0.50).timeout
	AudioManager.play_countdown()
	await get_tree().create_timer(start_delay).timeout
	AudioManager.play_countdown()
	
	state = State.MOVING
	AudioManager.start_move(current_size >= 3)

func _process(delta: float) -> void:
	match state:
		State.STARTING, State.DYING, State.FINISHED:
			return
			
		State.WAITING_FOR_CHOICE:
			read_direction_input()
			if buffered_direction == Vector2i.ZERO:
				return
				
			var wanted_cell := current_cell + buffered_direction
			if wanted_cell not in junction_options:
				return
				
			if not board.can_traverse(current_cell, wanted_cell, current_size):
				return
			set_next_cell(wanted_cell)
			buffered_direction = Vector2i.ZERO
			junction_options.clear()
			state = State.MOVING
			AudioManager.start_move(current_size >= 3)
		State.MOVING:
			read_direction_input()
			move_along_edge(delta)

func set_next_cell(cell: Vector2i) -> void:
	next_cell = cell
	update_facing()

func move_along_edge(delta: float) -> void:
	var from := board.grid_to_global(current_cell)
	var to := board.grid_to_global(next_cell)

	var distance := from.distance_to(to)

	if distance <= 0.0:
		return

	progress += (speed * delta) / distance

	if progress >= 1.0:
		global_position = to

		previous_cell = current_cell
		current_cell = next_cell
		
		progress = 0.0

		arrive_at_cell()
		return

	global_position = from.lerp(to, progress)

func arrive_at_cell() -> void:
	if !apply_component():
		return
	
	if current_cell == board.level.end_cell:
		win()
		return

	var neighbors: Array = board.get_neighbors(current_cell)

	var forward_options: Array[Vector2i] = []

	for neighbor: Vector2i in neighbors:
		if neighbor != previous_cell:
			forward_options.append(neighbor)

	if forward_options.is_empty():
		hit_dead_end()
		return

	if forward_options.size() == 1:
		var candidate: Vector2i = forward_options[0]
		
		if not board.can_traverse(current_cell, candidate, current_size):
			hit_blocked_wire(candidate)
			return
		
		set_next_cell(candidate)
		return
		
	junction_options = forward_options
	
	if settings.difficulty == GameSettings.Difficulty.EASY:
		state = State.WAITING_FOR_CHOICE
		AudioManager.stop_move()
		return
		
	choose_junction_automatically()

func choose_junction_automatically() -> void:
	if buffered_direction != Vector2i.ZERO:
		var wanted_cell := current_cell + buffered_direction
		
		if (wanted_cell in junction_options and 
			board.can_traverse(current_cell,wanted_cell,current_size)):
			
			set_next_cell(wanted_cell)
			buffered_direction = Vector2i.ZERO
			junction_options.clear()
			return
	
	var straight_direction := current_cell - previous_cell
	var straight_cell := current_cell + straight_direction
	
	if (straight_cell in junction_options and 
		board.can_traverse(current_cell,straight_cell,current_size)):
		
		set_next_cell(straight_cell)
		junction_options.clear()
		return
	
	hit_dead_end()

func apply_component() -> bool:
	var component: CircuitComponentData = board.get_component_at(current_cell)
	
	if component == null:
		return true
	
	var new_size := current_size
	match component.type:
		CircuitComponentData.CircuitComponentType.RESISTOR:
			new_size -= component.strength
		CircuitComponentData.CircuitComponentType.CAPACITOR:
			new_size += component.strength
	
	if new_size < 1 or new_size > 3:
		hit_dead_end()
		return false
	
	current_size = new_size
	update_electron_sprite()
	AudioManager.update_move(current_size >= 3)
	
	size_changed.emit(current_size)
	return true

func hit_dead_end() -> void:
	if state == State.DYING:
		return
	state = State.DYING

	buffered_direction = Vector2i.ZERO
	junction_options.clear()

	AudioManager.stop_move()
	AudioManager.play_death()
	await play_death_animation()
	
	death_animation_finished.emit()

func play_death_animation() -> void:
	sprite.visible = false
	await get_tree().create_timer(death_flash_time).timeout

	sprite.visible = true
	await get_tree().create_timer(death_flash_time).timeout

	sprite.visible = false
	await get_tree().create_timer(death_flash_time).timeout

	sprite.visible = true
	await get_tree().create_timer(death_flash_time * 0.7).timeout

	sprite.visible = false
	await get_tree().create_timer(death_flash_time * 0.7).timeout

	sprite.visible = true
	await get_tree().create_timer(death_flash_time * 0.5).timeout

	sprite.visible = false

	await get_tree().create_timer(0.25).timeout

func hit_blocked_wire(_target: Vector2i) -> void:
	hit_dead_end()

func win() -> void:
	if state == State.FINISHED:
		return
	state = State.FINISHED
	AudioManager.stop_move()
	AudioManager.play_complete()
	level_completed.emit()

func read_direction_input() -> void:
	var new_direction := Vector2i.ZERO

	if Input.is_action_just_pressed("ui_up"):
		new_direction = Vector2i.UP

	elif Input.is_action_just_pressed("ui_down"):
		new_direction = Vector2i.DOWN

	elif Input.is_action_just_pressed("ui_left"):
		new_direction = Vector2i.LEFT

	elif Input.is_action_just_pressed("ui_right"):
		new_direction = Vector2i.RIGHT

	if new_direction != Vector2i.ZERO:
		buffered_direction = new_direction
		print("Buffered direction: ", buffered_direction)

func create_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	var frames := SpriteFrames.new()

	frames.add_animation("thin")
	frames.set_animation_speed("thin", 8.0)
	frames.set_animation_loop("thin", true)

	for texture: Texture2D in ELECTRON_THIN: frames.add_frame("thin",texture)

	frames.add_animation("normal")
	frames.set_animation_speed("normal", 8.0)
	frames.set_animation_loop("normal", true)

	for texture: Texture2D in ELECTRON_NORMAL: frames.add_frame("normal",texture)

	frames.add_animation("thick")
	frames.set_animation_speed("thick", 8.0)
	frames.set_animation_loop("thick", true)

	for texture: Texture2D in ELECTRON_THICK: frames.add_frame("thick",texture)

	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 10

	add_child(sprite)

func update_electron_sprite() -> void:
	match current_size:
		1: sprite.play("thin")
		2: sprite.play("normal")
		3: sprite.play("thick")
		_:
			push_warning("No electron sprite for size %d" % current_size)

func update_facing() -> void:
	if sprite == null:
		return

	var direction: Vector2i = next_cell - current_cell

	match direction:
		Vector2i.RIGHT:
			sprite.rotation_degrees = 0

		Vector2i.DOWN:
			sprite.rotation_degrees = 90

		Vector2i.LEFT:
			sprite.rotation_degrees = 180

		Vector2i.UP:
			sprite.rotation_degrees = 270
