extends RefCounted
class_name PcbArt

const PCB_TEXTURES: Array[Texture2D] = [
	preload("res://art/pcb/pcb1.png"),
	preload("res://art/pcb/pcb2.png"),
	preload("res://art/pcb/pcb3.png"),
	preload("res://art/pcb/pcb4.png"),
]

static func get_pcb_texture(variant: int) -> Texture2D:
	var index: Variant = clamp(variant - 1, 0, PCB_TEXTURES.size() - 1)
	return PCB_TEXTURES[index]
