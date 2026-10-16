class_name PauseMenu
extends Control

@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var restart_btn: Button = $Panel/VBox/RestartButton
@onready var settings_btn: Button = $Panel/VBox/SettingsButton
@onready var menu_btn: Button = $Panel/VBox/MenuButton
@onready var settings_menu: Control = $SettingsMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
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
	_resume()
	GameManager.restart_current_level()

func _main_menu() -> void:
	_resume()
	GameManager.return_to_main_menu()
