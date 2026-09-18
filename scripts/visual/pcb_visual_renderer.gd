extends RefCounted
class_name PcbVisualRenderer

static func render_region(parent: Node, circuit_cell_scene: PackedScene, min_cell: Vector2i,
			max_cell_exclusive: Vector2i, cell_size: int, pcb_variant: int, graph: CircuitGraph,
			start_cell: Variant = null, end_cell: Variant = null) -> void:
		
		_create_background(parent,min_cell,max_cell_exclusive,cell_size,pcb_variant)
		var occupied_cells := graph.get_cell_set()
		for cell_position: Vector2i in occupied_cells:
			if not _is_inside_region(cell_position,min_cell,max_cell_exclusive):
				continue
			_render_circuit_cell(parent, circuit_cell_scene, cell_position, cell_size,
				pcb_variant, graph, start_cell, end_cell)

static func _create_background(parent: Node, min_cell: Vector2i, max_cell_exclusive: Vector2i,
	cell_size: int, pcb_variant: int) -> void:
	
	var background := PcbBackgroundLayer.new()
	background.name = "PcbBackground"
	parent.add_child(background)
	background.setup(min_cell,max_cell_exclusive,cell_size,pcb_variant)

static func _render_circuit_cell(parent: Node, circuit_cell_scene: PackedScene,
	cell_position: Vector2i, cell_size: int, pcb_variant: int, graph: CircuitGraph,
	start_cell: Variant, end_cell: Variant) -> void:
	var directions: Array[Vector2i] = []
	var wire_widths: Dictionary = {}

	for neighbor: Vector2i in graph.get_neighbors( cell_position):
		var direction := (neighbor - cell_position)
		var edge := graph.get_edge_between(cell_position,neighbor)
		directions.append(direction)
		if edge != null:
			wire_widths[direction] = edge.width

	var component := graph.get_component_at(cell_position)
	var is_start: bool = (start_cell != null and cell_position == start_cell)
	var is_end: bool = (end_cell != null and cell_position == end_cell)

	var cell: CircuitCell = circuit_cell_scene.instantiate()

	parent.add_child(cell)

	cell.setup(cell_position, cell_size, directions, wire_widths, is_start,
		is_end, component, pcb_variant)


static func _is_inside_region(cell: Vector2i, min_cell: Vector2i, 
			max_cell_exclusive: Vector2i) -> bool:
	return (cell.x >= min_cell.x and cell.y >= min_cell.y
	and cell.x < max_cell_exclusive.x and cell.y < max_cell_exclusive.y)
