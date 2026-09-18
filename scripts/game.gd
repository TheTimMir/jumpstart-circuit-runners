extends Node2D

@export var settings: GameSettings
@onready var board = $Board
@onready var electron: Electron = $Electron
@onready var camera: Camera2D = $Camera2D
@onready var pause_menu = $ui/PauseMenu
@onready var complete_menu = $ui/CompleteMenu
@onready var hud: GameHUD = $ui/GameHud
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !board.is_ready_for_gameplay:
		print("Board failed to initialise")
		return
	
	if settings == null:
		push_error("GameSettings not assigned")
		return
	settings.difficulty = GameSession.difficulty
	electron.death_animation_finished.connect(GameSession.retry_level)
	electron.level_completed.connect(_on_level_completed)
	electron.setup(board, settings)
	
	var start_position = board.grid_to_global(board.level.start_cell)
	var board_top_left = board.global_position
	var board_size := Vector2(board.level.width * board.level.cell_size,
	board.level.height * board.level.cell_size)
	var board_bottom_right = board_top_left + board_size

	camera.limit_left = int(board_top_left.x)
	camera.limit_top = int(board_top_left.y)
	camera.limit_right = int(board_bottom_right.x)
	camera.limit_bottom = int(board_bottom_right.y)
	camera.limit_smoothed = true
	camera.global_position = start_position
	camera.reset_smoothing()
	
	hud.setup(GameSession.selected_level_index + 1, GameSession.difficulty,
	board.level.start_electron_size)
	electron.size_changed.connect(hud.set_electron_size)
	show_level_tutorial()
	
func _on_level_completed() -> void:
	await get_tree().create_timer(0.7).timeout
	complete_menu.show_complete()

func _process(_delta: float) -> void:
	camera.global_position = electron.global_position

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused: pause_menu.close()
		else: pause_menu.open()
		get_viewport().set_input_as_handled()

func show_level_tutorial() -> void:
	var level_number := (GameSession.selected_level_index + 1)

	match level_number:
		1: hud.show_hint("You are an electron. 
		You can only enter wires as wide as you are.")
		2: hud.show_hint("At junctions, use arrow keys to choose a path.")
		3: hud.show_hint("Resistors make you smaller.\nCapacitiors make you larger.")
		4: hud.show_hint("You have to go towards the orange via.")
		5: hud.show_hint("Have fun! Made with <3 for Haven Jumpstart!" )
