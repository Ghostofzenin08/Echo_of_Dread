class_name PauseMenu
extends Control

@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var restart_btn: Button = $Panel/VBox/RestartButton
@onready var menu_btn: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if resume_btn:
		resume_btn.pressed.connect(_resume)
	if restart_btn:
		restart_btn.pressed.connect(_restart)
	if menu_btn:
		menu_btn.pressed.connect(_main_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not GameManager.is_narrative_open:
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
	visible = false
	get_tree().paused = false
	GameManager.is_paused = false

func _restart() -> void:
	_resume()
	GameManager.restart_current_level()

func _main_menu() -> void:
	_resume()
	GameManager.return_to_main_menu()
