extends Control

@onready var level_grid: GridContainer = %LevelGrid
@onready var easy_button: Button = %EasyButton
@onready var medium_button: Button = %MediumButtion
@onready var hard_button: Button = %HardButton
@onready var diff_note_label: Label = %DifficultyNoteLabel


func _ready() -> void:
	for child in level_grid.get_children(): child.queue_free()

	for i in range(GameSession.levels.size()):
		var button := Button.new()

		button.text = str(i + 1)
		button.custom_minimum_size = Vector2(40, 40)

		button.pressed.connect(_on_level_pressed.bind(i))
		level_grid.add_child(button)
		
	update_difficulty_buttons()

func _on_level_pressed(index: int) -> void:
	AudioManager.play_select()
	GameSession.selected_level_index = index
	GameSession.start_level()
	
func _on_easy_button_pressed() -> void:
	set_difficulty(GameSettings.Difficulty.EASY)

func _on_medium_buttion_pressed() -> void:
	set_difficulty(GameSettings.Difficulty.MEDIUM)

func _on_hard_button_pressed() -> void:
	set_difficulty(GameSettings.Difficulty.HARD)

func set_difficulty(new_difficulty: GameSettings.Difficulty) -> void:
	AudioManager.play_select()
	GameSession.difficulty = new_difficulty
	update_difficulty_buttons()

func update_difficulty_buttons() -> void:
	match GameSession.difficulty:
		GameSettings.Difficulty.EASY:
			diff_note_label.text = "Electron is slow and stops at intersections."
		GameSettings.Difficulty.MEDIUM:
			diff_note_label.text = "Input is buffered. Without input, you continue straight."
		GameSettings.Difficulty.HARD:
			diff_note_label.text = "Same rules as Medium, but FASTER."
	easy_button.disabled = (GameSession.difficulty == GameSettings.Difficulty.EASY)
	medium_button.disabled = (GameSession.difficulty ==GameSettings.Difficulty.MEDIUM)
	hard_button.disabled = (GameSession.difficulty ==GameSettings.Difficulty.HARD)

func _on_back_button_pressed() -> void:
	AudioManager.play_select()
	GameSession.go_to_main_menu()
