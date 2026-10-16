class_name SettingsMenu
extends Control

# SettingsMenu: Accessible modal configuration panel for Echo of Dread.
# Manages Audio bus volume sliders (Master, SFX, Music / Ambience),
# Visual toggles (Screen Shake, CRT / Temporal Shader),
# and Progress Reset with confirmation safety barrier.

signal closed
signal reset_completed

@onready var master_slider: HSlider = find_child("MasterSlider", true, false) as HSlider
@onready var master_val_label: Label = find_child("MasterValue", true, false) as Label
@onready var sfx_slider: HSlider = find_child("SFXSlider", true, false) as HSlider
@onready var sfx_val_label: Label = find_child("SFXValue", true, false) as Label
@onready var music_slider: HSlider = find_child("MusicSlider", true, false) as HSlider
@onready var music_val_label: Label = find_child("MusicValue", true, false) as Label

@onready var screen_shake_toggle: CheckBox = find_child("ScreenShakeToggle", true, false) as CheckBox
@onready var crt_shader_toggle: CheckBox = find_child("CRTShaderToggle", true, false) as CheckBox

@onready var reset_button: Button = find_child("ResetButton", true, false) as Button
@onready var back_button: Button = find_child("BackButton", true, false) as Button

@onready var confirm_modal: PanelContainer = find_child("ConfirmModal", true, false) as PanelContainer
@onready var confirm_reset_btn: Button = find_child("ConfirmResetButton", true, false) as Button
@onready var cancel_reset_btn: Button = find_child("CancelResetButton", true, false) as Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bind_controls()
	load_current_settings()
	if confirm_modal:
		confirm_modal.visible = false

func _bind_controls() -> void:
	if master_slider and not master_slider.value_changed.is_connected(_on_master_slider_changed):
		master_slider.value_changed.connect(_on_master_slider_changed)
	if sfx_slider and not sfx_slider.value_changed.is_connected(_on_sfx_slider_changed):
		sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	if music_slider and not music_slider.value_changed.is_connected(_on_music_slider_changed):
		music_slider.value_changed.connect(_on_music_slider_changed)
		
	if screen_shake_toggle and not screen_shake_toggle.toggled.is_connected(_on_screen_shake_toggled):
		screen_shake_toggle.toggled.connect(_on_screen_shake_toggled)
	if crt_shader_toggle and not crt_shader_toggle.toggled.is_connected(_on_crt_shader_toggled):
		crt_shader_toggle.toggled.connect(_on_crt_shader_toggled)
		
	if reset_button and not reset_button.pressed.is_connected(_on_reset_pressed):
		reset_button.pressed.connect(_on_reset_pressed)
	if back_button and not back_button.pressed.is_connected(close_menu):
		back_button.pressed.connect(close_menu)
		
	if confirm_reset_btn and not confirm_reset_btn.pressed.is_connected(confirm_reset):
		confirm_reset_btn.pressed.connect(confirm_reset)
	if cancel_reset_btn and not cancel_reset_btn.pressed.is_connected(cancel_reset):
		cancel_reset_btn.pressed.connect(cancel_reset)

func load_current_settings() -> void:
	if not SaveManager:
		return
	var master_pct := int(roundf(float(SaveManager.get_setting("master_volume", 1.0)) * 100.0))
	var sfx_pct := int(roundf(float(SaveManager.get_setting("sfx_volume", 1.0)) * 100.0))
	var music_pct := int(roundf(float(SaveManager.get_setting("music_volume", 1.0)) * 100.0))
	var shake := bool(SaveManager.get_setting("screen_shake", true))
	var crt := bool(SaveManager.get_setting("crt_shader", true))
	
	if master_slider:
		master_slider.set_value_no_signal(master_pct)
	if master_val_label:
		master_val_label.text = "%d%%" % master_pct
		
	if sfx_slider:
		sfx_slider.set_value_no_signal(sfx_pct)
	if sfx_val_label:
		sfx_val_label.text = "%d%%" % sfx_pct
		
	if music_slider:
		music_slider.set_value_no_signal(music_pct)
	if music_val_label:
		music_val_label.text = "%d%%" % music_pct
		
	if screen_shake_toggle:
		screen_shake_toggle.set_pressed_no_signal(shake)
	if crt_shader_toggle:
		crt_shader_toggle.set_pressed_no_signal(crt)

func _on_master_slider_changed(value: float) -> void:
	var linear := clampf(value / 100.0, 0.0, 1.0)
	if master_val_label:
		master_val_label.text = "%d%%" % int(value)
	if SaveManager:
		SaveManager.set_setting("master_volume", linear)

func _on_sfx_slider_changed(value: float) -> void:
	var linear := clampf(value / 100.0, 0.0, 1.0)
	if sfx_val_label:
		sfx_val_label.text = "%d%%" % int(value)
	if SaveManager:
		SaveManager.set_setting("sfx_volume", linear)

func _on_music_slider_changed(value: float) -> void:
	var linear := clampf(value / 100.0, 0.0, 1.0)
	if music_val_label:
		music_val_label.text = "%d%%" % int(value)
	if SaveManager:
		SaveManager.set_setting("music_volume", linear)

func _on_screen_shake_toggled(toggled_on: bool) -> void:
	if SaveManager:
		SaveManager.set_setting("screen_shake", toggled_on)

func _on_crt_shader_toggled(toggled_on: bool) -> void:
	if SaveManager:
		SaveManager.set_setting("crt_shader", toggled_on)

func _on_reset_pressed() -> void:
	SoundManager.play_sfx("click")
	if confirm_modal:
		confirm_modal.visible = true
	else:
		confirm_reset()

func confirm_reset() -> void:
	if SaveManager:
		SaveManager.reset_all_progress()
	load_current_settings()
	if confirm_modal:
		confirm_modal.visible = false
	SoundManager.play_sfx("alarm")
	reset_completed.emit()

func cancel_reset() -> void:
	SoundManager.play_sfx("click")
	if confirm_modal:
		confirm_modal.visible = false

func open_menu() -> void:
	_bind_controls()
	load_current_settings()
	if confirm_modal:
		confirm_modal.visible = false
	visible = true

func close_menu() -> void:
	SoundManager.play_sfx("click")
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		if confirm_modal and confirm_modal.visible:
			cancel_reset()
		else:
			close_menu()
		get_viewport().set_input_as_handled()
