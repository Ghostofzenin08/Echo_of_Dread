class_name PauseMenu
extends Control

@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var restart_btn: Button = $Panel/VBox/RestartButton
@onready var settings_btn: Button = $Panel/VBox/SettingsButton
@onready var menu_btn: Button = $Panel/VBox/MenuButton
@onready var settings_menu: Control = $SettingsMenu

var _buttons: Array[Button] = []
var _hover_tweens: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	_buttons = [resume_btn, restart_btn, settings_btn, menu_btn]
	for btn in _buttons:
		if is_instance_valid(btn):
			btn.pivot_offset = btn.size * 0.5
			btn.resized.connect(func(): if is_instance_valid(btn): btn.pivot_offset = btn.size * 0.5)
			btn.mouse_entered.connect(func(): _animate_button_hover(btn, true))
			btn.mouse_exited.connect(func(): _animate_button_hover(btn, false))
			btn.focus_entered.connect(func(): _animate_button_hover(btn, true))
			btn.focus_exited.connect(func(): _animate_button_hover(btn, false))
			
	if resume_btn:
		resume_btn.pressed.connect(_resume)
	if restart_btn:
		restart_btn.pressed.connect(_restart)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_main_menu)
	if settings_menu:
		settings_menu.visible = false

func _animate_button_hover(btn: Button, is_hovered: bool) -> void:
	if not is_instance_valid(btn):
		return
	if _hover_tweens.has(btn) and is_instance_valid(_hover_tweens[btn]):
		_hover_tweens[btn].kill()
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hover_tweens[btn] = tw
	var target_scale := Vector2(1.05, 1.05) if is_hovered else Vector2.ONE
	var target_color := Color(0.2, 0.9, 1.0, 1.0) if is_hovered else Color(1.0, 1.0, 1.0, 1.0)
	tw.tween_property(btn, "scale", target_scale, 0.15)
	tw.tween_property(btn, "modulate", target_color, 0.15)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not GameManager.is_narrative_open:
		if settings_menu and settings_menu.visible:
			if settings_menu.has_method("close_menu"):
				settings_menu.close_menu()
			else:
				settings_menu.visible = false
			get_viewport().set_input_as_handled()
			return
		if visible:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()

func _pause() -> void:
	visible = true
	get_tree().paused = true
	GameManager.is_paused = true

func _resume() -> void:
	SoundManager.play_sfx("click")
	if settings_menu:
		settings_menu.visible = false
	visible = false
	get_tree().paused = false
	GameManager.is_paused = false

func _on_settings_pressed() -> void:
	SoundManager.play_sfx("click")
	if settings_menu:
		if settings_menu.has_method("open_menu"):
			settings_menu.open_menu()
		else:
			settings_menu.visible = true

func _restart() -> void:
	SoundManager.play_sfx("click")
	_resume()
	GameManager.restart_current_level()

func _main_menu() -> void:
	SoundManager.play_sfx("click")
	_resume()
	GameManager.return_to_main_menu()
