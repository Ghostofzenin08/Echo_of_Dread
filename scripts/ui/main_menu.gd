class_name MainMenu
extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var level_select_button: Button = $VBoxContainer/LevelSelectButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var how_to_play_button: Button = $VBoxContainer/HowToPlayButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var guide_modal: PanelContainer = $GuideModal
@onready var guide_close_btn: Button = $GuideModal/Margin/VBox/CloseButton
@onready var settings_menu: Control = $SettingsMenu

func _ready() -> void:
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
	if guide_close_btn:
		guide_close_btn.pressed.connect(func(): guide_modal.visible = false)
	if guide_modal:
		guide_modal.visible = false
	if settings_menu:
		settings_menu.visible = false

func _on_start_pressed() -> void:
	SoundManager.play_sfx("click")
	GameManager.start_game()

func _on_level_select_pressed() -> void:
	SoundManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_settings_pressed() -> void:
	SoundManager.play_sfx("click")
	if settings_menu:
		if settings_menu.has_method("open_menu"):
			settings_menu.open_menu()
		else:
			settings_menu.visible = true

func _on_how_to_play_pressed() -> void:
	SoundManager.play_sfx("click")
	if guide_modal:
		guide_modal.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()
