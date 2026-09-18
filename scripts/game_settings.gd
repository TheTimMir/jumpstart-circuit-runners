extends Resource
class_name GameSettings

enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}

@export var difficulty: Difficulty = Difficulty.EASY

@export_group("Speed")
@export var easy_speed: float = 120.0
@export var medium_speed: float = 180.0
@export var hard_speed: float = 280.0
