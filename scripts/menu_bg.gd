extends Control
class_name MenuBackground


@export var circuit_cell_scene: PackedScene
@export var decoration_profile: PcbDecorationProfile

@export var cell_size: int = 64

@export_range(1, 4, 1)
var pcb_variant: int = 1

@export_range(0, 6, 1)
var padding_cells: int = 2

@export var refresh_interval: float = 10.0
@export var fade_time: float = 1.2


@onready var layer_a: Node2D = $LayerA
@onready var layer_b: Node2D = $LayerB
@onready var refresh_timer: Timer = $RefreshTimer

var showing_a := true
var transition_in_progress := false

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	
	render_into_layer(layer_a)

	layer_a.visible = true
	layer_a.modulate = Color(1, 1, 1, 1)
	
	layer_b.visible = false
	layer_b.modulate = Color(1, 1, 1, 0)
	
	refresh_timer.wait_time = refresh_interval
	refresh_timer.one_shot = false
	refresh_timer.timeout.connect(_on_refresh_timer_timeout)
	refresh_timer.start()
	
func _on_refresh_timer_timeout() -> void:
	if transition_in_progress:
		return
		
	await regenerate_background()


func regenerate_background() -> void:
	if transition_in_progress:
		return

	transition_in_progress = true

	var current_layer: Node2D
	var next_layer: Node2D

	if showing_a:
		current_layer = layer_a
		next_layer = layer_b
	else:
		current_layer = layer_b
		next_layer = layer_a

	render_into_layer(next_layer)

	next_layer.visible = true
	next_layer.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(next_layer, "modulate:a", 1.0, fade_time)
	tween.tween_property(current_layer, "modulate:a", 0.0, fade_time)
	await tween.finished
	
	current_layer.visible = false
	showing_a = not showing_a
	transition_in_progress = false
	
func render_into_layer(target_layer: Node2D) -> void:
	clear_layer(target_layer)
	var viewport_size := get_viewport_rect().size
	var visible_columns := int(ceil(viewport_size.x / float(cell_size)))
	var visible_rows := int(ceil(viewport_size.y / float(cell_size)))
	var total_columns := visible_columns+ padding_cells * 2
	var total_rows := visible_rows + padding_cells * 2
	var region := Rect2i(Vector2i.ZERO,Vector2i(total_columns,total_rows))
	var graph := PcbDecorGenerator.generate(region, {}, rng.randi(),
	0, decoration_profile)
	
	target_layer.position = Vector2(-padding_cells * cell_size,
									-padding_cells * cell_size)
	
	PcbVisualRenderer.render_region(target_layer, circuit_cell_scene,
		Vector2i.ZERO, Vector2i(total_columns, total_rows),
		cell_size,pcb_variant, graph)
	
func clear_layer(layer: Node) -> void:
	for child in layer.get_children():
		child.free()
