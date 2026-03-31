extends Control

const TITLE_IMAGE_PATH := "res://assets/images/title.png"
const BASE_STATUS := "Play starts the run. Codex is a placeholder. Exit closes the game."

const BUTTON_NORMAL_SCALE := Vector2(1.0, 1.0)
const BUTTON_HOVER_SCALE := Vector2(1.05, 1.05)
const BUTTON_PRESS_SCALE := Vector2(0.97, 0.97)
const BUTTON_NORMAL_TINT := Color(1.0, 1.0, 1.0, 1.0)
const BUTTON_HOVER_TINT := Color(1.08, 1.08, 1.18, 1.0)
const BUTTON_PRESS_TINT := Color(0.92, 0.92, 1.05, 1.0)
const PLAY_TRANSITION_SECONDS := 2.0
const EXIT_TRANSITION_SECONDS := 4.0

@onready var title_texture_rect: TextureRect = $MainLayout/Panel/Content/TitleImage
@onready var panel: Panel = $MainLayout/Panel
@onready var ambient_tint: ColorRect = $AmbientTint
@onready var status_label: Label = $MainLayout/Panel/Content/StatusLabel
@onready var buttons_container: VBoxContainer = $MainLayout/Panel/Content/Buttons
@onready var play_button: Button = $MainLayout/Panel/Content/Buttons/PlayButton
@onready var codex_button: Button = $MainLayout/Panel/Content/Buttons/CodexButton
@onready var exit_button: Button = $MainLayout/Panel/Content/Buttons/ExitButton

var _button_tweens: Dictionary = {}
var _menu_time: float = 0.0
var _panel_base_position: Vector2
var _is_play_transitioning: bool = false
var _is_exit_transitioning: bool = false
var _play_shimmer: ColorRect
var _play_shimmer_material: ShaderMaterial
var _exit_underlay_non_title: ColorRect
var _exit_top_wipe: ColorRect
var _exit_title_overlay: TextureRect


func _ready() -> void:
	_panel_base_position = panel.position
	_setup_dynamic_buttons()
	_setup_play_transition_fx()
	_setup_exit_transition_fx()
	set_process(true)

	if FileAccess.file_exists(TITLE_IMAGE_PATH):
		var image := Image.new()
		var load_error := image.load(TITLE_IMAGE_PATH)
		if load_error == OK:
			title_texture_rect.texture = ImageTexture.create_from_image(image)
			# Keep title on top so it draws after menu controls.
			title_texture_rect.z_index = 20
			# Make the title art appear larger.
			title_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			status_label.text = BASE_STATUS
		else:
			status_label.text = "Could not load assets/images/title.png as an image file."
	else:
		status_label.text = "Missing title image at assets/images/title.png"


func _process(delta: float) -> void:
	_menu_time += delta
	panel.position.y = _panel_base_position.y + sin(_menu_time * 1.2) * 3.0
	ambient_tint.color.a = 0.09 + (sin(_menu_time * 0.8) * 0.015)


func _setup_dynamic_buttons() -> void:
	for child in buttons_container.get_children():
		var button := child as Button
		if button == null:
			continue

		button.focus_mode = Control.FOCUS_NONE
		button.pivot_offset = button.size * 0.5
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.mouse_exited.connect(_on_button_unhovered.bind(button))
		button.button_down.connect(_on_button_pressed_visual.bind(button))
		button.button_up.connect(_on_button_released_visual.bind(button))
		_animate_button(button, BUTTON_NORMAL_SCALE, BUTTON_NORMAL_TINT, 0.01)


func _setup_play_transition_fx() -> void:
	play_button.clip_contents = true
	_play_shimmer = ColorRect.new()
	_play_shimmer.name = "PlayShimmer"
	_play_shimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_play_shimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_shimmer.z_index = 60
	_play_shimmer.visible = false
	_play_shimmer.color = Color(1, 1, 1, 1)

	var shimmer_shader := Shader.new()
	shimmer_shader.code = """
shader_type canvas_item;
uniform vec4 shimmer_color : source_color = vec4(1.0, 1.0, 1.0, 0.9);
uniform float progress = -0.5;

void fragment() {
	vec2 uv = UV;
	float diagonal = uv.x - uv.y;
	float center = mix(-1.2, 1.2, progress);
	float width = mix(0.03, 0.26, clamp(uv.y, 0.0, 1.0));
	float band = 1.0 - smoothstep(width, width + 0.06, abs(diagonal - center));
	COLOR = vec4(shimmer_color.rgb, band * shimmer_color.a);
}
"""

	_play_shimmer_material = ShaderMaterial.new()
	_play_shimmer_material.shader = shimmer_shader
	_play_shimmer.material = _play_shimmer_material
	play_button.add_child(_play_shimmer)


func _on_button_hovered(button: Button) -> void:
	if _is_play_transitioning or _is_exit_transitioning:
		return
	if button.text.begins_with("Play"):
		status_label.text = "Start a new run now."
	elif button.text.begins_with("Codex"):
		status_label.text = "Codex is a placeholder menu option for now."
	elif button.text.begins_with("Exit"):
		status_label.text = "Exit the game."
	_animate_button(button, BUTTON_HOVER_SCALE, BUTTON_HOVER_TINT, 0.12)


func _on_button_unhovered(button: Button) -> void:
	if _is_play_transitioning or _is_exit_transitioning:
		return
	status_label.text = BASE_STATUS
	_animate_button(button, BUTTON_NORMAL_SCALE, BUTTON_NORMAL_TINT, 0.12)


func _on_button_pressed_visual(button: Button) -> void:
	if (_is_play_transitioning and button != play_button) or _is_exit_transitioning:
		return
	_animate_button(button, BUTTON_PRESS_SCALE, BUTTON_PRESS_TINT, 0.06)


func _on_button_released_visual(button: Button) -> void:
	if _is_play_transitioning or _is_exit_transitioning:
		return
	if button.is_hovered():
		_animate_button(button, BUTTON_HOVER_SCALE, BUTTON_HOVER_TINT, 0.08)
	else:
		_animate_button(button, BUTTON_NORMAL_SCALE, BUTTON_NORMAL_TINT, 0.08)


func _animate_button(button: Button, scale_target: Vector2, tint_target: Color, duration: float) -> void:
	var key := button.get_path()
	if _button_tweens.has(key):
		var previous_tween := _button_tweens[key] as Tween
		if previous_tween:
			previous_tween.kill()

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(button, "scale", scale_target, duration)
	tween.parallel().tween_property(button, "modulate", tint_target, duration)
	_button_tweens[key] = tween


func _on_play_button_pressed() -> void:
	if _is_play_transitioning or _is_exit_transitioning:
		return
	_is_play_transitioning = true
	_begin_play_transition_visuals()
	await get_tree().create_timer(1.0).timeout
	_start_play_shimmer()
	await get_tree().create_timer(max(PLAY_TRANSITION_SECONDS - 1.0, 0.0)).timeout
	GameState.start_new_run()
	get_tree().change_scene_to_file("res://scenes/GameRoot.tscn")


func _begin_play_transition_visuals() -> void:
	status_label.text = "Launching run..."
	codex_button.disabled = true
	exit_button.disabled = true

	var gold_style := StyleBoxFlat.new()
	gold_style.bg_color = Color(0.86, 0.67, 0.18, 1.0)
	gold_style.border_width_left = 4
	gold_style.border_width_top = 4
	gold_style.border_width_right = 4
	gold_style.border_width_bottom = 4
	gold_style.border_color = Color(1.0, 0.96, 0.86, 1.0)
	gold_style.corner_radius_top_left = 10
	gold_style.corner_radius_top_right = 10
	gold_style.corner_radius_bottom_right = 10
	gold_style.corner_radius_bottom_left = 10

	play_button.add_theme_stylebox_override("normal", gold_style)
	play_button.add_theme_stylebox_override("hover", gold_style)
	play_button.add_theme_stylebox_override("pressed", gold_style)
	play_button.add_theme_stylebox_override("disabled", gold_style)
	play_button.add_theme_stylebox_override("focus", gold_style)
	play_button.add_theme_color_override("font_color", Color(0.19, 0.13, 0.03, 1.0))
	play_button.add_theme_color_override("font_hover_color", Color(0.19, 0.13, 0.03, 1.0))
	play_button.add_theme_color_override("font_pressed_color", Color(0.19, 0.13, 0.03, 1.0))
	play_button.scale = BUTTON_NORMAL_SCALE
	play_button.modulate = Color(1, 1, 1, 1)

	_play_shimmer.visible = false
	_play_shimmer.modulate = Color(1, 1, 1, 1)
	_play_shimmer_material.set_shader_parameter("progress", -0.35)


func _start_play_shimmer() -> void:
	_play_shimmer.visible = true
	_play_shimmer.modulate = Color(1, 1, 1, 1)
	_play_shimmer_material.set_shader_parameter("progress", -0.35)

	var shimmer_tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	shimmer_tween.tween_method(
		func(v: float) -> void:
			_play_shimmer_material.set_shader_parameter("progress", v),
		-0.35,
		1.35,
		0.75
	)
	shimmer_tween.parallel().tween_property(_play_shimmer, "modulate:a", 0.0, 0.25).set_delay(0.62)


func _setup_exit_transition_fx() -> void:
	_exit_underlay_non_title = ColorRect.new()
	_exit_underlay_non_title.name = "ExitUnderlayNonTitle"
	_exit_underlay_non_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_exit_underlay_non_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exit_underlay_non_title.z_index = 18
	_exit_underlay_non_title.color = Color(0, 0, 0, 0)
	add_child(_exit_underlay_non_title)

	_exit_top_wipe = ColorRect.new()
	_exit_top_wipe.name = "ExitTopWipe"
	_exit_top_wipe.anchor_left = 0.0
	_exit_top_wipe.anchor_top = 0.0
	_exit_top_wipe.anchor_right = 1.0
	_exit_top_wipe.anchor_bottom = 0.0
	_exit_top_wipe.offset_left = 0.0
	_exit_top_wipe.offset_top = 0.0
	_exit_top_wipe.offset_right = 0.0
	_exit_top_wipe.offset_bottom = 0.0
	_exit_top_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exit_top_wipe.z_index = 100
	_exit_top_wipe.color = Color(0, 0, 0, 1)
	add_child(_exit_top_wipe)


func _begin_exit_transition_visuals() -> void:
	status_label.text = "Exiting..."
	play_button.disabled = true
	codex_button.disabled = true
	exit_button.disabled = true

	# Build a top-level title overlay so it can animate freely to center.
	var title_start_position := title_texture_rect.get_global_rect().position
	var title_size := title_texture_rect.size
	_exit_title_overlay = TextureRect.new()
	_exit_title_overlay.name = "ExitTitleOverlay"
	_exit_title_overlay.texture = title_texture_rect.texture
	_exit_title_overlay.stretch_mode = title_texture_rect.stretch_mode
	_exit_title_overlay.expand_mode = title_texture_rect.expand_mode
	_exit_title_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exit_title_overlay.z_index = 25
	_exit_title_overlay.position = title_start_position
	_exit_title_overlay.size = title_size
	_exit_title_overlay.modulate = Color(1, 1, 1, 1)
	add_child(_exit_title_overlay)
	title_texture_rect.visible = false

	# t=0 to t=2: title moves from original position to center screen.
	var viewport_size := get_viewport_rect().size
	var centered_position := (viewport_size * 0.5) - (title_size * 0.5)
	var title_move_tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	title_move_tween.tween_property(_exit_title_overlay, "position", centered_position, 2.0)

	# Everything except title image darkens in 1 second.
	var underlay_tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	underlay_tween.tween_property(_exit_underlay_non_title, "color:a", 1.0, 1.0)

	# Title image darkens steadily from t=0 to t=3.
	var title_tween := create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	title_tween.tween_property(_exit_title_overlay, "modulate", Color(0, 0, 0, 1), EXIT_TRANSITION_SECONDS)

	# After 1 second, a top black wipe covers the window over 2 seconds.
	var viewport_height := viewport_size.y
	var wipe_tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	wipe_tween.tween_interval(1.0)
	wipe_tween.tween_property(_exit_top_wipe, "offset_bottom", viewport_height, 2.0)


func _on_codex_button_pressed() -> void:
	status_label.text = "CODEX is a fake button right now (coming soon)."


func _on_exit_button_pressed() -> void:
	if _is_exit_transitioning or _is_play_transitioning:
		return
	_is_exit_transitioning = true
	_begin_exit_transition_visuals()
	await get_tree().create_timer(EXIT_TRANSITION_SECONDS).timeout
	get_tree().quit()
