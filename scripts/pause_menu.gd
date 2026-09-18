extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func open() -> void:
	visible = true
	get_tree().paused = true

func close() -> void:
	get_tree().paused = false
	visible = false

func _on_resume_button_pressed() -> void:
	AudioManager.play_select()
	close()

func _on_restart_button_pressed() -> void:
	AudioManager.play_select()
	get_tree().paused = false
	GameSession.retry_level()

func _on_menu_button_pressed() -> void:
	AudioManager.play_select()
	GameSession.go_to_main_menu()
