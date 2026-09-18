extends Node

const GAME_SCENE := "res://scenes/game.tscn"
const MENU_SCENE := "res://scenes/main.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/level_select.tscn"

var selected_level_index: int = 0
var difficulty: GameSettings.Difficulty = GameSettings.Difficulty.EASY


var levels: Array[String] 

func _ready() -> void:
	for i in range(1, 15):
		var path = "res://levels/level_%02d.tres" % i
		levels.append(path)

func get_selected_level() -> CircuitLevelData:
	if selected_level_index < 0 \
	or selected_level_index >= levels.size():
		push_warning("SENDING NULL AS LEVEL")
		return null

	return load(levels[selected_level_index]) as CircuitLevelData

func start_level() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func retry_level() -> void:
	get_tree().reload_current_scene()

func next_level() -> void:
	if selected_level_index + 1 >= levels.size():
		go_to_level_select()
		return

	selected_level_index += 1
	start_level()

func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)

func go_to_level_select() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)
