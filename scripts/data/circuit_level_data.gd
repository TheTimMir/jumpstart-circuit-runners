extends Resource
class_name CircuitLevelData

@export_group("Board")
@export var width: int = 8
@export var height: int = 8
@export var cell_size: int = 96
@export_range(1, 4, 1) var pcb_variant: int = 1

@export_group("Gameplay")
@export var start_cell: Vector2i
@export var end_cell: Vector2i
@export var start_electron_size: int = 2

@export_group("Circuit")
@export var edges: Array[CircuitEdgeData] = []
@export var components: Array[CircuitComponentData] = []

@export_group("Decoration")

@export var decoration_enabled: bool = true
@export var decoration_seed: int = 1
@export_range(0, 3, 1)
var decoration_clearance: int = 1
@export_range(0, 8, 1)
var decoration_padding: int = 4
@export var decoration_profile: PcbDecorationProfile


# TODO legacy, remove
@export_range(0.0, 1.0, 0.05)
var decoration_density: float = 0.50

@export_range(3, 20, 1)
var decoration_cluster_min_cells: int = 5

@export_range(3, 30, 1)
var decoration_cluster_max_cells: int = 12

@export_range(0.0, 1.0, 0.05)
var decoration_cluster_chance: float = 0.80

@export_range(0.0, 1.0, 0.05)
var decoration_branchiness: float = 0.25
