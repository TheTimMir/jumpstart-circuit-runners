extends Node2D
class_name CircuitCell

const SOURCE_SIZE := 32.0
const WIRE_TEXTURES := {
	1: preload("res://art/wires/thinwire.png"),
	2: preload("res://art/wires/normwire.png"),
	3: preload("res://art/wires/thickwire.png"),
}
const CORNER_TEXTURES := {
	1: preload("res://art/wires/thinwirecorner.png"),
	2: preload("res://art/wires/normwirecorner.png"),
	3: preload("res://art/wires/thickwirecorner.png"),
}
const LEG_TEXTURES := {
	1: preload("res://art/wires/thinleg.png"),
	2: preload("res://art/wires/normleg.png"),
	3: preload("res://art/wires/thickleg.png"),
}
const JUNCTION_BODY: Texture2D = preload("res://art/components/body.png")
const VIA_TEXTURE: Texture2D = preload("res://art/components/via.png")
const RESISTOR_1_2: Texture2D = preload("res://art/components/thinresistor.png")
const RESISTOR_2_3: Texture2D = preload("res://art/components/normresistor.png")
const CAPACITOR_1_2: Texture2D = preload("res://art/components/thincapacitor.png")
const CAPACITOR_2_3: Texture2D = preload("res://art/components/normcapacitor.png")

var grid_pos: Vector2i
var cell_size: int = 64
var pcb_variant: int = 1

var connections: Array[Vector2i] = []
var wire_widths: Dictionary = {}

var is_start := false
var is_end := false
var include_pcb_background := true
var component: CircuitComponentData = null

func setup(new_grid_pos: Vector2i, new_cell_size: int,
			new_conns: Array[Vector2i], new_wire_widths: Dictionary, start: bool,
			end: bool, new_component: CircuitComponentData, new_pcb_variant: int,
			new_include_pcb_background: bool = true) -> void:
	grid_pos = new_grid_pos
	cell_size = new_cell_size
	connections = new_conns
	wire_widths = new_wire_widths
	is_start = start
	is_end = end
	component = new_component
	pcb_variant = new_pcb_variant
	include_pcb_background = new_include_pcb_background

	position = Vector2(
		grid_pos.x * cell_size,
		grid_pos.y * cell_size
	)

	build_visuals()

func build_visuals() -> void:
	for child in get_children():
		child.queue_free()

	if include_pcb_background:
		add_sprite(PcbArt.get_pcb_texture(pcb_variant),0)

	if connections.is_empty():
		return
	if component != null:
		add_component_cell()
		return
	
	match connections.size():
		1: add_dead_end()
		2: add_two_way_path()
		3, 4: add_junction()

func add_sprite(texture: Texture2D,z: int = 0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.position = Vector2(cell_size / 2.0,cell_size / 2.0)
	var art_scale := cell_size / SOURCE_SIZE
	sprite.scale = Vector2.ONE * art_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = z
	add_child(sprite)
	return sprite

func get_width(direction: Vector2i) -> int:
	return int(wire_widths.get(direction, 1))
func get_wire_texture(width: int) -> Texture2D:
	return WIRE_TEXTURES.get(clamp(width, 1, 3),WIRE_TEXTURES[1])
func get_corner_texture(width: int) -> Texture2D:
	return CORNER_TEXTURES.get(clamp(width, 1, 3),CORNER_TEXTURES[1])
func get_leg_texture(width: int) -> Texture2D:
	return LEG_TEXTURES.get(clamp(width, 1, 3),LEG_TEXTURES[1])

#region Paths
func add_two_way_path() -> void:
	var a: Vector2i = connections[0]
	var b: Vector2i = connections[1]

	var width_a := get_width(a)
	var width_b := get_width(b)

	var opposite := a + b == Vector2i.ZERO

	if opposite:
		add_straight_path(a,width_a,width_b)
	else:
		add_corner_path(a,b,width_a,width_b)

func add_straight_path(direction: Vector2i,width_a: int,width_b: int) -> void:
	if width_a != width_b:
		add_half_trace(connections[0],width_a)
		add_half_trace(connections[1],width_b)
		return

	var sprite := add_sprite(get_wire_texture(width_a),1)
	if direction == Vector2i.UP or direction == Vector2i.DOWN:
		sprite.rotation_degrees = 90

func add_corner_path(a: Vector2i,b: Vector2i,width_a: int,width_b: int) -> void:
	if width_a != width_b:
		add_half_trace(a, width_a)
		add_half_trace(b, width_b)
		return

	var sprite := add_sprite(get_corner_texture(width_a),1)
	sprite.rotation_degrees = corner_rotation(a, b)

func corner_rotation(a: Vector2i,b: Vector2i) -> float:
	# This assumes the unrotated corner PNG connects LEFT + DOWN
	if has_directions(a, b, Vector2i.LEFT, Vector2i.DOWN): return 0.0

	if has_directions(a, b, Vector2i.LEFT, Vector2i.UP): return 90.0

	if has_directions(a, b, Vector2i.RIGHT, Vector2i.UP): return 180.0

	if has_directions(a, b, Vector2i.RIGHT, Vector2i.DOWN): return 270.0

	return 0.0

func has_directions(a: Vector2i,b: Vector2i,wanted_a: Vector2i,wanted_b: Vector2i) -> bool:
	return ((a == wanted_a and b == wanted_b) or (a == wanted_b and b == wanted_a))

func add_half_trace(direction: Vector2i,width: int) -> void:
	var full_texture := get_wire_texture(width)

	var half_texture := AtlasTexture.new()
	half_texture.atlas = full_texture
	
	half_texture.region = Rect2(16,0,16,32)
	var sprite := Sprite2D.new()

	sprite.texture = half_texture
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 1

	var art_scale := cell_size / SOURCE_SIZE
	sprite.scale = Vector2.ONE * art_scale

	var center := Vector2(cell_size / 2.0,cell_size / 2.0)
	var offset := 8.0 * art_scale
	sprite.position = center + Vector2(direction.x,direction.y) * offset
	
	match direction:
		Vector2i.RIGHT:
			sprite.rotation_degrees = 0

		Vector2i.DOWN:
			sprite.rotation_degrees = 90

		Vector2i.LEFT:
			sprite.rotation_degrees = 180

		Vector2i.UP:
			sprite.rotation_degrees = 270

	add_child(sprite)
#endregion

func add_dead_end() -> void:
	var direction := connections[0]
	var width := get_width(direction)

	add_half_trace(direction,width)
	var via := add_sprite(VIA_TEXTURE,3)
	if is_start:
		via.modulate = Color(0.55,0.85,1.0)

	elif is_end:
		via.modulate = Color(1.0,0.75,0.45)

func add_junction() -> void:
	add_sprite(JUNCTION_BODY,2)

	for direction: Vector2i in connections:
		add_junction_leg(direction,get_width(direction))

func add_junction_leg(direction: Vector2i,width: int) -> void:
	var sprite := add_sprite(get_leg_texture(width),1)
	# Base leg points LEFT
	match direction:
		Vector2i.LEFT:
			sprite.rotation_degrees = 0

		Vector2i.UP:
			sprite.rotation_degrees = 90

		Vector2i.RIGHT:
			sprite.rotation_degrees = 180

		Vector2i.DOWN:
			sprite.rotation_degrees = 270

func add_component_cell() -> void:
	for direction: Vector2i in connections:
		add_half_trace(direction,get_width(direction))

	var texture := get_component_texture()
	if texture == null: return
	var sprite := add_sprite(texture,3)
	orient_component(sprite)

func get_component_texture() -> Texture2D:
	if connections.size() != 2:
		push_warning("Component at %s should have exactly 2 connections" % grid_pos)
		return null

	var width_a := get_width(connections[0])
	var width_b := get_width(connections[1])

	var low = min(width_a, width_b)
	var high = max(width_a, width_b)

	match component.type:
		CircuitComponentData.CircuitComponentType.RESISTOR:
			if low == 1 and high == 2:
				return RESISTOR_1_2

			if low == 2 and high == 3:
				return RESISTOR_2_3

		CircuitComponentData.CircuitComponentType.CAPACITOR:
			if low == 1 and high == 2:
				return CAPACITOR_1_2

			if low == 2 and high == 3:
				return CAPACITOR_2_3

	push_warning("No component texture for width transition %d -> %d at %s" % 
	[width_a, width_b, grid_pos])

	return null

func orient_component(sprite: Sprite2D) -> void:
	if connections.size() != 2: return

	var horizontal := (Vector2i.LEFT in connections and Vector2i.RIGHT in connections)

	var vertical := (Vector2i.UP in connections and Vector2i.DOWN in connections)

	if horizontal:
		sprite.rotation_degrees = 0
		var left_width := get_width(Vector2i.LEFT)
		var right_width := get_width(Vector2i.RIGHT)
		sprite.flip_h = left_width > right_width

	elif vertical:
		sprite.rotation_degrees = 90
		var up_width := get_width(Vector2i.UP)
		var down_width := get_width(Vector2i.DOWN)
		sprite.flip_h = up_width > down_width

	else:
		push_warning("Component at %s is placed on a corner" % grid_pos)
