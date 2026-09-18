extends Resource
class_name PcbDecorationProfile


@export_range(0.0, 1.0, 0.05)
var density: float = 0.50

@export_range(3, 20, 1)
var cluster_min_cells: int = 5

@export_range(3, 30, 1)
var cluster_max_cells: int = 12

@export_range(0.0, 1.0, 0.05)
var cluster_chance: float = 0.80

@export_range(0.0, 1.0, 0.05)
var branchiness: float = 0.25
