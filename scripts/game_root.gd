extends Node2D

@onready var hp_value: Label = $UI/HUD/Margin/RootRows/TopRow/HPValue
@onready var wave_value: Label = $UI/HUD/Margin/RootRows/TopRow/WaveValue
@onready var high_score_value: Label = $UI/HUD/Margin/RootRows/TopRow/HighScoreValue
@onready var info_label: Label = $UI/HUD/Margin/RootRows/BottomRow/InfoLabel


func _ready() -> void:
	_refresh_hud()
	info_label.text = "Foundation scene: arena border + HUD + placeholder loop."


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	if event.is_action_pressed("ui_accept"):
		GameState.current_wave += 1
		_refresh_hud()
		return
	if event.is_action_pressed("ui_select"):
		GameState.take_damage(10)
		_refresh_hud()
		if not GameState.run_active:
			info_label.text = "Run ended. Press ESC to return to menu."


func _refresh_hud() -> void:
	hp_value.text = str(GameState.current_hp)
	wave_value.text = str(GameState.current_wave)
	high_score_value.text = str(GameState.high_score)
