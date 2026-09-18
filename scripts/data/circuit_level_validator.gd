extends RefCounted
class_name CircuitLevelValidator

static func validate(level: CircuitLevelData) -> PackedStringArray:
	var errors := PackedStringArray()
	
	if level == null:
		errors.append("Level is null")
		return errors
	
	validate_board_settings(level, errors)
	validate_edges(level, errors)
	validate_components(level, errors)
	
	if errors.is_empty(): validate_graphs(level, errors)
	
	return errors

static func validate_board_settings(level: CircuitLevelData,
errors:PackedStringArray) -> void:
	if level.width <= 0: 
		errors.append("Board width must be greater that 0")
	if level.height <= 0: 
		errors.append("Board height must be greater that 0")
	if level.cell_size <= 0: 
		errors.append("Cell Size must be greater that 0")
	if !is_inside_board(level, level.start_cell):
		errors.append("Start cell %s is outside the board" % level.start_cell)
	if !is_inside_board(level, level.end_cell):
		errors.append("End cell %s is outside the board" % level.end_cell)
	if level.start_cell == level.end_cell:
		errors.append("Start cell and exit cell cannot be the same")
	if level.start_electron_size <= 0:
		errors.append("Electron size must be greater than 0")

static func validate_edges(level: CircuitLevelData,
errors:PackedStringArray) -> void:
	var seen_edges: Dictionary = {}
	
	for i in range(level.edges.size()):
		var edge: CircuitEdgeData = level.edges[i]
		
		if edge == null:
			errors.append("Edge %d is null" % i)
			continue
			
		if !is_inside_board(level, edge.from):
			errors.append("Edge %d starts from outside the board: %s" % 
			[i, edge.from])
		if !is_inside_board(level, edge.to):
			errors.append("Edge %d ends from outside the board: %s" % 
			[i, edge.to])
		if edge.from == edge.to:
			errors.append("Edge %d connects to itself: %s" % [i, edge.from])
		
		var offset: Vector2i = edge.to - edge.from
		if abs(offset.x) + abs(offset.y) != 1:
			errors.append("Edge %d connects non-adjacent cells: %s -> %s" %
			[i, edge.from, edge.to])
		if edge.width <= 0:
			errors.append("Edge %d has ivalid width %d" % [i, edge.width])
		
		var key:= make_edge_key(edge.from, edge.to)
		
		if seen_edges.has(key):
			errors.append("Edge %d duplicates an exising edge: %s <-> %s" %
			[i, edge.from, edge.to])
		else:
			seen_edges[key] = true

static func validate_components(level: CircuitLevelData,
errors:PackedStringArray) -> void:
	var occupied: Dictionary = {}
	for i in range(level.components.size()):
		var component: CircuitComponentData = level.components[i]
		
		if component == null:
			errors.append("Component %d is null" % i)
			continue
			
		if component.strength <= 0 :
			errors.append("Component %d has invaid strenght %d" % 
			[i, component.strength])
		if not is_inside_board(level, component.position):
			errors.append("Component %d is outside the board at %s" %
			[i, component.position])
		if occupied.has(component.position):
			errors.append("Multiple components at cell %s" % component.position)
		else:
			occupied[component.position] = true

static func validate_graphs(level: CircuitLevelData,
errors:PackedStringArray) -> void:
	var graph := build_graph(level)
	
	var start_neighbors: Array = graph.get(level.start_cell, [])
	var end_neighbors: Array = graph.get(level.end_cell, [])

	if start_neighbors.size() != 1:
		errors.append("Start cell %s must have exactly 1 connection, not %d" % 
		[level.start_cell, start_neighbors.size()])
	if end_neighbors.size() != 1:
		errors.append("End cell %s must have exactly 1 connection, not %d" % 
		[level.end_cell, end_neighbors.size()])
	
	if !path_exists(graph, level.start_cell, level.end_cell):
		errors.append("No path exists from start %s to exit %s" % 
		[level.start_cell, level.end_cell])
	
	# components should sit somewhere on the circiut
	for i in range(level.components.size()):
		var component: CircuitComponentData = level.components[i]
		
		if component == null:
			continue
		
		if !graph.has(component.position):
			errors.append("Component %d at %s is not placed on the circuit" %
			[i, component.position])


static func build_graph(level: CircuitLevelData) -> Dictionary:
	var graph: Dictionary = {}
	
	for edge: CircuitEdgeData in level.edges:
		if !graph.has(edge.from):
			graph[edge.from] = []
		if !graph.has(edge.to):
			graph[edge.to] = []
		
		graph[edge.from].append(edge.to)
		graph[edge.to].append(edge.from)
		
	return graph

static func path_exists(graph:Dictionary,start:Vector2i,target:Vector2i) -> bool:
	if not graph.has(start):
		return false
	
	var queue: Array[Vector2i] = [start]
	var visisted: Dictionary = {start: true}
	
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		
		if current == target:
			return true	
		for neighbor: Vector2i in graph.get(current, []):
			if not visisted.has(neighbor):
				visisted[neighbor] = true
				queue.append(neighbor)
	return false

static func is_inside_board(level:CircuitLevelData,cell:Vector2i) -> bool:
	return (cell.x >=0 and 
			cell.y>=0 and 
			cell.x<level.width and 
			cell.y<level.height)

static func make_edge_key(a:Vector2i, b:Vector2i) -> String:
	# edges a-b and b-a need to count as the same edge
	if a.x < b.x or (a.x == b.x and a.y<b.y):
		return "%d,%d:%d,%d" % [a.x, a.y, b.x, b.y]
	return "%d,%d:%d,%d" % [b.x, b.y, a.x, a.y]
