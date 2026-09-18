extends Node2D
class_name CircuitBoard

@export var circuit_cell_scene: PackedScene

var level: CircuitLevelData

var gameplay_graph: CircuitGraph
var decoration_graph: CircuitGraph
var visual_graph: CircuitGraph

var is_ready_for_gameplay := false

func _ready() -> void:
	level = GameSession.get_selected_level()
	
	if level.decoration_profile == null:
		push_error("no PcbDecorationProfile") #TODO remove 
		decoration_graph = CircuitGraph.new()
		return
	
	if circuit_cell_scene == null:
		push_error("Board missing CircuitCell assignment")
		return
	
	var validation_errors: PackedStringArray = CircuitLevelValidator.validate(level)
	
	if not validation_errors.is_empty():
		push_error("Level validation failed:\n- " + "\n- ".join(validation_errors))
		return

	build_graphs()
	build_visuals()

	is_ready_for_gameplay = true


func build_graphs() -> void:
	gameplay_graph = CircuitGraph.from_data(level.edges,level.components)

	build_decoration_graph()

	visual_graph = CircuitGraph.merge(gameplay_graph, decoration_graph)


func build_decoration_graph() -> void:
	if not level.decoration_enabled:
		decoration_graph = CircuitGraph.new()
		return
	
	var gameplay_cells := gameplay_graph.get_cell_set()
	
	gameplay_cells[level.start_cell] = true
	gameplay_cells[level.end_cell] = true
	
	var padding := level.decoration_padding
	var region := Rect2i(Vector2i(-padding,-padding),
		Vector2i(level.width + padding * 2, level.height + padding * 2))
	decoration_graph = PcbDecorGenerator.generate(region, gameplay_cells,
		level.decoration_seed, level.decoration_clearance,
		level.decoration_profile)

func build_visuals() -> void:
	var padding := level.decoration_padding

	PcbVisualRenderer.render_region(self, circuit_cell_scene,
		Vector2i(-padding,-padding),
		Vector2i(level.width + padding,level.height + padding),
		level.cell_size,level.pcb_variant,visual_graph,level.start_cell,level.end_cell)

func grid_to_local(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * level.cell_size + level.cell_size / 2.0,
		cell.y * level.cell_size + level.cell_size / 2.0)


func grid_to_global(cell: Vector2i) -> Vector2:
	return to_global(grid_to_local(cell))


func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	return gameplay_graph.get_neighbors(cell)

func get_edge_between(a: Vector2i, b: Vector2i) -> CircuitEdgeData:
	return gameplay_graph.get_edge_between(a,b)

func get_component_at(cell: Vector2i) -> CircuitComponentData:
	return gameplay_graph.get_component_at(cell)

func can_traverse(from: Vector2i,to: Vector2i,electron_size: int) -> bool:
	var edge := gameplay_graph.get_edge_between(from,to)

	if edge == null:
		return false

	return electron_size <= edge.width
