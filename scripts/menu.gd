extends Control

func _on_play_button_pressed() -> void:
	AudioManager.play_select()
	GameSession.go_to_level_select()

func _on_quit_button_pressed() -> void:
	AudioManager.play_select()
	get_tree().quit()
