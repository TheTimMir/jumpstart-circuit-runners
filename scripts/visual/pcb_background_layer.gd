extends Node2D
class_name PcbBackgroundLayer

var min_cell := Vector2i.ZERO
var max_cell_exclusive := Vector2i.ZERO

var cell_size := 64
var pcb_variant := 1

func setup(new_min_cell: Vector2i, new_max_cell_exclusive: Vector2i, 
			new_cell_size: int, new_pcb_variant: int) -> void:
	min_cell = new_min_cell
	max_cell_exclusive = new_max_cell_exclusive
	cell_size = new_cell_size
	pcb_variant = new_pcb_variant

	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = -100

	queue_redraw()


func _draw() -> void:
	var texture := PcbArt.get_pcb_texture(pcb_variant)
	
	for y in range(min_cell.y, max_cell_exclusive.y ):
		for x in range(min_cell.x, max_cell_exclusive.x):
			var rect := Rect2(Vector2(x * cell_size,y * cell_size),
							  Vector2.ONE * cell_size)
			draw_texture_rect(texture,rect,false)
