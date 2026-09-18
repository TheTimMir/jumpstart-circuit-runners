extends Control
class_name GameHUD

@onready var level_label: Label = %LevelLabel
@onready var size_label: Label = %SizeLabel
@onready var difficulty_label: Label = %DifficultyLabel

@onready var hint_panel: Control = %HintPanel
@onready var hint_label: Label = %HintLabel

var hint_tween: Tween

func _ready() -> void:
	hint_panel.hide()

func setup(level_number: int, difficulty: GameSettings.Difficulty, electron_size: int) -> void:
	level_label.text = "LEVEL %02d" % level_number
	difficulty_label.text = get_difficulty_name(difficulty)
	
	set_electron_size(electron_size)

func set_electron_size(size: int) -> void:
	size_label.text = "SIZE %d" % size


func get_difficulty_name(difficulty: GameSettings.Difficulty) -> String:
	match difficulty:
		GameSettings.Difficulty.EASY:
			return "EASY"

		GameSettings.Difficulty.MEDIUM:
			return "MEDIUM"

		GameSettings.Difficulty.HARD:
			return "HARD"

	return "UNKNOWN" # sohuld never happen

func show_hint(text: String, duration: float = 5.0) -> void:
	if text.is_empty():
		hide_hint()
		return
	
	if hint_tween != null:
		hint_tween.kill()
	
	hint_label.text = text
	hint_panel.modulate.a = 0.0
	hint_panel.show()
	
	hint_tween = create_tween()
	hint_tween.tween_property(hint_panel,"modulate:a",1.0,0.2	)
	hint_tween.tween_interval(duration)
	hint_tween.tween_property(hint_panel,"modulate:a",0.0,0.35)
	hint_tween.tween_callback(hint_panel.hide)

func hide_hint() -> void:
	if hint_tween != null:
		hint_tween.kill()

	hint_panel.hide()
