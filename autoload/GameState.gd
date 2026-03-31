extends Node

const BASE_MAX_HP: int = 100

var high_score: int = 0
var current_wave: int = 1
var current_hp: int = BASE_MAX_HP
var run_active: bool = false


func start_new_run() -> void:
	current_wave = 1
	current_hp = BASE_MAX_HP
	run_active = true


func end_run() -> void:
	run_active = false
	var completed_wave: int = max(current_wave - 1, 0)
	high_score = max(high_score, completed_wave)


func take_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)
	if current_hp == 0 and run_active:
		end_run()
