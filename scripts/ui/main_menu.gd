class_name MainMenu
extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var level_select_button: Button = $VBoxContainer/LevelSelectButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var how_to_play_button: Button = $VBoxContainer/HowToPlayButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var guide_modal: Control = $GuideModal
@onready var guide_close_btn: Button = null
@onready var settings_menu: Control = $SettingsMenu

@onready var desktop_decorations: Control = get_node_or_null("Decorations")
@onready var header_box: Control = get_node_or_null("HeaderBox")
@onready var desktop_vbox: Control = get_node_or_null("VBoxContainer")

@onready var mobile_layout: Control = get_node_or_null("MobileLayout")
@onready var mobile_play_btn: Button = get_node_or_null("MobileLayout/MobileCenter/ButtonsRow/MobilePlayButton")
@onready var mobile_settings_btn: Button = get_node_or_null("MobileLayout/MobileCenter/ButtonsRow/MobileSettingsButton")
@onready var mobile_chamber_btn: Button = get_node_or_null("MobileLayout/MobileCenter/ButtonsRow/MobileChamberButton")
@onready var mobile_help_btn: Button = get_node_or_null("MobileLayout/MobileHelpButton")

var _buttons: Array[Button] = []
var _button_tweens: Dictionary = {}

func _ready() -> void:
	_buttons = [
		start_button,
		level_select_button,
		settings_button,
		how_to_play_button,
		quit_button
	]
	
	if mobile_play_btn:
		mobile_play_btn.pressed.connect(_on_start_pressed)
		_buttons.append(mobile_play_btn)
	if mobile_settings_btn:
		mobile_settings_btn.pressed.connect(_on_settings_pressed)
		_buttons.append(mobile_settings_btn)
	if mobile_chamber_btn:
		mobile_chamber_btn.pressed.connect(_on_level_select_pressed)
		_buttons.append(mobile_chamber_btn)
	if mobile_help_btn:
		mobile_help_btn.pressed.connect(_on_how_to_play_pressed)
		_buttons.append(mobile_help_btn)

	_check_and_apply_layout()
	if SaveManager and not SaveManager.settings_changed.is_connected(_check_and_apply_layout):
		SaveManager.settings_changed.connect(_check_and_apply_layout)
	
	# Connect existing game logic
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if level_select_button:
		level_select_button.pressed.connect(_on_level_select_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if how_to_play_button:
		how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	if guide_modal:
		guide_close_btn = guide_modal.find_child("BackButton", true, false) as Button
		if guide_close_btn == null:
			guide_close_btn = guide_modal.find_child("CloseButton", true, false) as Button
		if guide_close_btn:
			guide_close_btn.pressed.connect(func():
				SoundManager.play_sfx("click")
				guide_modal.visible = false
			)
		guide_modal.visible = false
	if settings_menu:
		settings_menu.visible = false

	# Setup button hover effects (scale slightly on hover only)
	_setup_button_effects()

func _check_and_apply_layout() -> void:
	var is_mobile: bool = GameManager.is_mobile_device() if GameManager else (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"))
	if mobile_layout:
		mobile_layout.visible = is_mobile
	if header_box:
		header_box.visible = true
	if is_mobile:
		if desktop_decorations: desktop_decorations.visible = false
		if desktop_vbox: desktop_vbox.visible = false
	else:
		if desktop_decorations: desktop_decorations.visible = true
		if desktop_vbox: desktop_vbox.visible = true

func _setup_button_effects() -> void:
	for btn in _buttons:
		if not is_instance_valid(btn):
			continue
		btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_button_hover.bind(btn, false))
		btn.focus_entered.connect(_on_button_hover.bind(btn, true))
		btn.focus_exited.connect(_on_button_hover.bind(btn, false))

func _on_button_hover(btn: Button, is_hovered: bool) -> void:
	if not is_instance_valid(btn):
		return
	if _button_tweens.has(btn) and is_instance_valid(_button_tweens[btn]):
		_button_tweens[btn].kill()
	
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_button_tweens[btn] = tween
	
	var target_scale := Vector2(1.02, 1.02) if is_hovered else Vector2(1.0, 1.0)
	var target_modulate := Color(1.12, 1.12, 1.12, 1.0) if is_hovered else Color(1.0, 1.0, 1.0, 1.0)
	
	tween.tween_property(btn, "scale", target_scale, 0.15)
	tween.tween_property(btn, "modulate", target_modulate, 0.15)

func _animate_button_click(btn: Button, callback: Callable) -> void:
	if not is_instance_valid(btn):
		callback.call()
		return
		
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(0.97, 0.97), 0.06)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.08)
	tween.tween_callback(callback)

# ==============================================================================
# Game Workflow & Logic (STRICTLY PRESERVED)
# ==============================================================================

func _on_start_pressed() -> void:
	SoundManager.play_sfx("click")
	_animate_button_click(start_button, func(): GameManager.start_game())

func _on_level_select_pressed() -> void:
	SoundManager.play_sfx("click")
	_animate_button_click(level_select_button, func(): get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn"))

func _on_settings_pressed() -> void:
	SoundManager.play_sfx("click")
	_animate_button_click(settings_button, func():
		if settings_menu:
			if settings_menu.has_method("open_menu"):
				settings_menu.open_menu()
			else:
				settings_menu.visible = true
	)

func _on_how_to_play_pressed() -> void:
	SoundManager.play_sfx("click")
	_animate_button_click(how_to_play_button, func():
		if guide_modal:
			guide_modal.visible = true
	)

func _on_quit_pressed() -> void:
	SoundManager.play_sfx("click")
	_animate_button_click(quit_button, func(): get_tree().quit())

func _unhandled_input(event: InputEvent) -> void:
	if guide_modal and guide_modal.visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
			guide_modal.visible = false
			get_viewport().set_input_as_handled()
