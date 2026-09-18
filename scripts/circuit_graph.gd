extends RefCounted
class_name CircuitGraph

var edges: Array[CircuitEdgeData] = []
var components: Array[CircuitComponentData] = []

var connections: Dictionary = {}
var edge_lookup: Dictionary = {}
var component_lookup: Dictionary = {}

static func from_data(source_edges: Array[CircuitEdgeData],
		source_components: Array[CircuitComponentData]) -> CircuitGraph:
	var graph := CircuitGraph.new()
	
	for edge: CircuitEdgeData in source_edges:
		if edge != null:
			graph.add_edge(edge)
			
	for component: CircuitComponentData in source_components:
		if component != null:
			graph.add_component(component)
			
	return graph

static func merge(primary: CircuitGraph, secondary: CircuitGraph) -> CircuitGraph:
	var result := CircuitGraph.new()

	if primary != null:
		for edge: CircuitEdgeData in primary.edges:
			result.add_edge(edge)

		for component: CircuitComponentData in primary.components:
			result.add_component(component)

	if secondary != null:
		for edge: CircuitEdgeData in secondary.edges:
			var key := edge_key(edge.from, edge.to)

			if not result.edge_lookup.has(key):
				result.add_edge(edge)

		for component: CircuitComponentData in secondary.components:
			if not result.component_lookup.has(component.position):
				result.add_component(component)

	return result

func add_edge(edge: CircuitEdgeData) -> void:
	var key := edge_key(edge.from, edge.to)

	if edge_lookup.has(key):
		return

	edges.append(edge)
	edge_lookup[key] = edge

	add_connection(edge.from, edge.to)
	add_connection(edge.to, edge.from)

func add_component(component: CircuitComponentData) -> void:
	if component_lookup.has(component.position):
		return

	components.append(component)
	component_lookup[component.position] = component

func add_connection(from: Vector2i, to: Vector2i) -> void:
	var neighbors: Array[Vector2i] = []

	if connections.has(from):
		neighbors = connections[from]

	neighbors.append(to)
	connections[from] = neighbors

func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if not connections.has(cell):
		return result

	for neighbor: Vector2i in connections[cell]:
		result.append(neighbor)

	return result

func get_edge_between(a: Vector2i, b: Vector2i) -> CircuitEdgeData:
	return edge_lookup.get(edge_key(a, b)) as CircuitEdgeData

func get_component_at(cell: Vector2i) -> CircuitComponentData:
	return component_lookup.get(cell) as CircuitComponentData

func get_cell_set() -> Dictionary:
	var cells: Dictionary = {}

	for edge: CircuitEdgeData in edges:
		cells[edge.from] = true
		cells[edge.to] = true

	for component: CircuitComponentData in components:
		cells[component.position] = true

	return cells

static func edge_key(a: Vector2i,b: Vector2i) -> Vector4i:
	if (a.x < b.x or (a.x == b.x and a.y <= b.y)):
		return Vector4i(a.x,a.y, b.x,b.y)
	return Vector4i(b.x,b.y, a.x,a.y)

func has_cell(cell: Vector2i) -> bool:
	return (connections.has(cell) or component_lookup.has(cell))

func is_empty() -> bool:
	return edges.is_empty() and components.is_empty()
