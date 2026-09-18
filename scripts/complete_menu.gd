extends Control

func show_complete() -> void:
	visible = true

func _on_next_button_pressed() -> void:
	AudioManager.play_select()
	GameSession.next_level()

func _on_retry_button_pressed() -> void:
	AudioManager.play_select()
	GameSession.retry_level()
	
func _on_level_select_button_pressed() -> void:
	AudioManager.play_select()
	GameSession.go_to_level_select()
