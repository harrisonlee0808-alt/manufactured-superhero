extends Control

@onready var status_label: Label = $MainLayout/Panel/Content/StatusLabel


func _on_play_button_pressed() -> void:
	status_label.text = "PLAY is a fake button right now (coming soon)."


func _on_cards_button_pressed() -> void:
	status_label.text = "CARDS is a fake button right now (coming soon)."


func _on_arena_prototype_button_pressed() -> void:
	GameState.start_new_run()
	get_tree().change_scene_to_file("res://scenes/GameRoot.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
