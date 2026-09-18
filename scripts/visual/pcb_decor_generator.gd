extends RefCounted
class_name PcbDecorGenerator

static func generate(region: Rect2i, forbidden_cells: Dictionary, seed: int,
	clearance: int, profile: PcbDecorationProfile) -> CircuitGraph:
	
	var graph := CircuitGraph.new()

	if profile == null:
		push_error("PcbDecorGenerator requires a PcbDecorationProfile")
		return graph
		
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var forbidden := build_forbidden_cells(forbidden_cells, clearance )
	var occupied: Dictionary = {}
	
	var min_x := region.position.x
	var min_y := region.position.y

	var max_x := (region.position.x + region.size.x - 1)
	var max_y := (region.position.y + region.size.y - 1)
	var total_cells := (region.size.x * region.size.y )
	var forbidden_inside_region := 0

	for cell: Vector2i in forbidden:
		if region.has_point(cell):
			forbidden_inside_region += 1
			
	var available_cells: Variant = max(0, total_cells - forbidden_inside_region)
	var target_occupied_cells := int(available_cells * profile.density)
	var placement_attempts := 0
	var max_placement_attempts := total_cells * 8
	
	# try to grow clusters of motifs
	# if cant, fallback to single motifs
	while (occupied.size() < target_occupied_cells 
		and placement_attempts < max_placement_attempts):
		
		placement_attempts += 1
		var origin := Vector2i(rng.randi_range(min_x, max_x),
								rng.randi_range(min_y, max_y))

		if rng.randf() < profile.cluster_chance:
			var placed := try_grow_cluster(origin, rng, profile, forbidden,
			occupied, min_x, min_y, max_x, max_y, graph)
			
			if placed:
				continue
			var rotation := rng.randi_range(0, 3)
			var motif := create_random_motif(rng)
			try_place_motif(motif,origin,rotation,forbidden,occupied,min_x,
							min_y,max_x,max_y,graph)
	return graph

#region motifs
static func try_place_motif(motif: Dictionary, origin: Vector2i, rotation: int,
		forbidden: Dictionary, occupied: Dictionary, min_x: int, min_y: int,
		max_x: int, max_y: int, graph: CircuitGraph) -> bool:
	var transformed_edges: Array = []
	var motif_cells: Dictionary = {}
	
	for edge_data: Array in motif["edges"]:
		var local_from: Vector2i = edge_data[0]
		var local_to: Vector2i = edge_data[1]
		var width: int = edge_data[2]
	
		var from := (origin + rotate_point(local_from,rotation))
		var to := (origin + rotate_point(local_to,rotation))
	
		if !inside_bounds(from,min_x,min_y,max_x,max_y):
			return false
	
		if !inside_bounds(to,min_x,min_y,max_x,max_y):
			return false
	
		motif_cells[from] = true
		motif_cells[to] = true
		transformed_edges.append([from, to, width])
	
	# reject overlap with gameplay or existing deco
	for cell: Vector2i in motif_cells:
		if forbidden.has(cell):
			return false
	
		if occupied.has(cell):
			return false
	
	# everythings good?
	for cell: Vector2i in motif_cells:
		occupied[cell] = true
	
	for edge_data: Array in transformed_edges:
		var edge := CircuitEdgeData.new()
	
		edge.from = edge_data[0]
		edge.to = edge_data[1]
		edge.width = edge_data[2]
	
		graph.add_edge(edge)
	
	var component_data = motif["component"]
	
	if component_data != null:
		var component := CircuitComponentData.new()
		component.position = (origin + rotate_point(component_data["position"],rotation))
		component.type = component_data["type"]
		component.strength = 1
		graph.add_component(component)
	
	return true

static func create_random_motif(rng: RandomNumberGenerator) -> Dictionary:
	var motif_type := rng.randi_range(0, 7)
	match motif_type:
		0:
			return motif_straight(rng)
		1:
			return motif_corner(rng)
		2:
			return motif_zigzag(rng)
		3:
			return motif_t_junction(rng)
		4:
			return motif_cross(rng)
		5:
			return motif_resistor(rng)
		6:
			return motif_capacitor(rng)
		7:
			return motif_stub(rng)
	return motif_straight(rng)

static func motif_straight(rng: RandomNumberGenerator) -> Dictionary:
	var width := rng.randi_range(1, 3)

	return {
		"edges": [[Vector2i(0, 0),Vector2i(1, 0),width],
				[Vector2i(1, 0),Vector2i(2, 0),width]],
		"component": null 
		}

static func motif_corner(rng: RandomNumberGenerator) -> Dictionary:
	var width := rng.randi_range(1, 3)
	return {
		"edges": [[Vector2i(0, 0),Vector2i(1, 0),width],
			[Vector2i(1, 0),Vector2i(1, 1),width]],
		"component": null }

static func motif_zigzag(rng: RandomNumberGenerator) -> Dictionary:
	var width := rng.randi_range(1, 3)

	return {
		"edges": [[Vector2i(0, 0),Vector2i(1, 0),width],
			[Vector2i(1, 0),Vector2i(1, 1),width],
			[Vector2i(1, 1),Vector2i(2, 1),width]],
		"component": null}

static func motif_t_junction(rng: RandomNumberGenerator) -> Dictionary:
	return {
		"edges": [[Vector2i(0, 0),Vector2i(-1, 0),rng.randi_range(1, 3)],
			[Vector2i(0, 0),Vector2i(1, 0),rng.randi_range(1, 3)],
			[Vector2i(0, 0),Vector2i(0, -1),rng.randi_range(1, 3)]],
		"component": null}

static func motif_cross(rng: RandomNumberGenerator) -> Dictionary:
	return {
		"edges": [[Vector2i.ZERO,Vector2i.LEFT,rng.randi_range(1, 3)],
			[Vector2i.ZERO,Vector2i.RIGHT,rng.randi_range(1, 3)],
			[Vector2i.ZERO,Vector2i.UP,rng.randi_range(1, 3)],
			[Vector2i.ZERO,Vector2i.DOWN,rng.randi_range(1, 3)]],
		"component": null}

static func motif_resistor(rng: RandomNumberGenerator) -> Dictionary:
	var low := rng.randi_range(1, 2)
	var high := low + 1

	return {
		"edges": [[Vector2i(0, 0),Vector2i(1, 0),low],
			[Vector2i(1, 0),Vector2i(2, 0),high]],
		"component": {
			"position": Vector2i(1, 0),
			"type":	CircuitComponentData.CircuitComponentType.RESISTOR 
			}}

static func motif_capacitor(rng: RandomNumberGenerator) -> Dictionary:
	var low := rng.randi_range(1, 2)
	var high := low + 1

	return {
		"edges": [[Vector2i(0, 0),Vector2i(1, 0),low],
			[Vector2i(1, 0),Vector2i(2, 0),high]],
		"component": {"position": Vector2i(1, 0),
		"type":CircuitComponentData.CircuitComponentType.CAPACITOR
		}}

static func motif_stub(rng: RandomNumberGenerator) -> Dictionary:
	var width := rng.randi_range(1, 3)

	return {
		"edges": [[Vector2i.ZERO,Vector2i.RIGHT,width]],
		"component": null }
#endregion

# ffing hell
static func try_grow_cluster(origin: Vector2i, rng: RandomNumberGenerator, 
		profile: PcbDecorationProfile, forbidden: Dictionary, occupied: Dictionary,
	min_x: int, min_y: int, max_x: int, max_y: int, graph: CircuitGraph)  -> bool:
	
	if not inside_bounds(origin,min_x,min_y,max_x,max_y):
		return false

	if forbidden.has(origin):
		return false

	if occupied.has(origin):
		return false

	var target_size := rng.randi_range(
		profile.cluster_min_cells,
		profile.cluster_max_cells)

	# для кластера одна ширина потому что я их не соединю потом 
	# TODO разные размеры
	var wire_width := rng.randi_range(1, 3)

	var cluster_cells: Dictionary = {}
	var cell_list: Array[Vector2i] = []
	var cluster_edges: Array = []

	cluster_cells[origin] = true
	cell_list.append(origin)

	var current_tip := origin

	var growth_attempts := 0
	var max_growth_attempts := target_size * 20


	while (cluster_cells.size() < target_size 
	and growth_attempts < max_growth_attempts):
		growth_attempts += 1

		var source := current_tip

		if (cell_list.size() > 1 and rng.randf() < profile.branchiness):
			source = cell_list[rng.randi_range(0,cell_list.size() - 1)]

		var direction := random_direction(rng)
		var next := source + direction

		if not inside_bounds(next,min_x,min_y,max_x,max_y):
			continue

		if forbidden.has(next):
			continue

		if occupied.has(next):
			continue

		if cluster_cells.has(next):
			continue


		# форсим не слишком плотную сети чтобы оно не спагеттилось
		if count_cluster_neighbors(next, cluster_cells) > 1:
			continue

		cluster_cells[next] = true
		cell_list.append(next)
		cluster_edges.append([source, next, wire_width])
		current_tip = next

	if cluster_cells.size() < 3: 
		return false

	for cell: Vector2i in cluster_cells:
		occupied[cell] = true

	for edge_data: Array in cluster_edges:
		var edge := CircuitEdgeData.new()

		edge.from = edge_data[0]
		edge.to = edge_data[1]
		edge.width = edge_data[2]
		graph.add_edge(edge)
	return true

static func rotate_point(point: Vector2i,quarter_turns: int) -> Vector2i:
	match quarter_turns % 4:
		0: return point
		1: return Vector2i(-point.y,point.x)
		2: return Vector2i(-point.x,-point.y)
		3: return Vector2i(point.y,-point.x)
	return point

static func inside_bounds(cell: Vector2i,min_x: int,min_y: int,max_x: int,max_y: int) -> bool:
	return (cell.x >= min_x and cell.x <= max_x and cell.y >= min_y and cell.y <= max_y)

static func build_forbidden_cells(gameplay_cells: Dictionary,clearance: int) -> Dictionary:
	var forbidden: Dictionary = {}

	for cell: Vector2i in gameplay_cells:
		for y in range(cell.y - clearance,cell.y + clearance + 1):
			for x in range(cell.x - clearance,cell.x + clearance + 1):
				forbidden[Vector2i(x, y)] = true
	return forbidden

static func count_cluster_neighbors(cell: Vector2i, cluster_cells: Dictionary) -> int:
	var count := 0

	if cluster_cells.has(cell + Vector2i.RIGHT):
		count += 1

	if cluster_cells.has(cell + Vector2i.LEFT):
		count += 1

	if cluster_cells.has(cell + Vector2i.UP):
		count += 1

	if cluster_cells.has(cell + Vector2i.DOWN):
		count += 1

	return count

static func random_direction(rng: RandomNumberGenerator) -> Vector2i:
	match rng.randi_range(0, 3):
		0: return Vector2i.RIGHT
		1: return Vector2i.DOWN
		2: return Vector2i.LEFT
		3: return Vector2i.UP
	return Vector2i.RIGHT # for it not to warn
