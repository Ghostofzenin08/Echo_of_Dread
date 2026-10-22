class_name GameHUD
extends CanvasLayer

@onready var chamber_label: Label = $TopBar/Margin/HBox/ChamberLabel
@onready var timer_label: Label = $TopBar/Margin/HBox/TimerContainer/TimerLabel
@onready var timer_bar: ProgressBar = $TopBar/Margin/HBox/TimerContainer/TimerBar
@onready var loop_label: Label = $TopBar/Margin/HBox/LoopLabel
@onready var echo_label: Label = $TopBar/Margin/HBox/EchoLabel

const TimelineWidgetClass = preload("res://scripts/ui/timeline_widget.gd")
const ChamberClearModalClass = preload("res://scripts/ui/chamber_clear_modal.gd")

@onready var timeline_widget: Control = get_node_or_null("TopBar/Margin/HBox/TimerContainer/TimelineWidget")
@onready var chamber_clear_modal: Control = get_node_or_null("ChamberClearModal")

@onready var rewind_flash: ColorRect = $RewindFlash
@onready var terminal_modal: PanelContainer = $TerminalModal
@onready var terminal_title: Label = $TerminalModal/Margin/VBox/TitleLabel
@onready var terminal_meta: Label = $TerminalModal/Margin/VBox/MetaLabel
@onready var terminal_content: RichTextLabel = $TerminalModal/Margin/VBox/ContentLabel
@onready var terminal_close_btn: Button = $TerminalModal/Margin/VBox/CloseButton

var _last_alarm_sec: int = -1

func _ready() -> void:
	if timeline_widget == null:
		var container := get_node_or_null("TopBar/Margin/HBox/TimerContainer")
		if container:
			timeline_widget = TimelineWidgetClass.new()
			container.add_child(timeline_widget)
			
	if chamber_clear_modal == null:
		var modal_scene := load("res://scenes/ui/chamber_clear_modal.tscn") as PackedScene
		if modal_scene:
			chamber_clear_modal = modal_scene.instantiate()
			chamber_clear_modal.name = "ChamberClearModal"
			add_child(chamber_clear_modal)
			
	if chamber_clear_modal:
		chamber_clear_modal.visible = false
		if not chamber_clear_modal.next_chamber_requested.is_connected(_on_modal_next):
			chamber_clear_modal.next_chamber_requested.connect(_on_modal_next)
		if not chamber_clear_modal.retry_chamber_requested.is_connected(_on_modal_retry):
			chamber_clear_modal.retry_chamber_requested.connect(_on_modal_retry)
		if not chamber_clear_modal.sector_select_requested.is_connected(_on_modal_select):
			chamber_clear_modal.sector_select_requested.connect(_on_modal_select)
			
	if rewind_flash:
		rewind_flash.color = Color(0.2, 0.8, 1.0, 0.0)
	if terminal_modal:
		terminal_modal.visible = false
	if terminal_close_btn:
		terminal_close_btn.pressed.connect(_on_close_terminal_pressed)
		
	if not GameManager.narrative_opened.is_connected(_on_narrative_opened):
		GameManager.narrative_opened.connect(_on_narrative_opened)
	if not GameManager.narrative_closed.is_connected(_on_narrative_closed):
		GameManager.narrative_closed.connect(_on_narrative_closed)
	if not GameManager.chamber_cleared.is_connected(_on_chamber_cleared):
		GameManager.chamber_cleared.connect(_on_chamber_cleared)

func set_chamber_title(title: String) -> void:
	if chamber_label:
		chamber_label.text = title

var current_level_number: int = 1
var duration_toggle_btn: Button = null

func set_level_number(lvl: int) -> void:
	current_level_number = lvl
	_update_duration_toggle_ui()
	var rewind_unlocked := lvl > 10 and (SaveManager == null or SaveManager.is_rewind_unlocked())
	set_rewind_available(rewind_unlocked)

func _ensure_duration_toggle_button() -> void:
	if duration_toggle_btn != null:
		return
	var container := get_node_or_null("TopBar/Margin/HBox") as HBoxContainer
	if container:
		duration_toggle_btn = Button.new()
		duration_toggle_btn.name = "DurationToggleBtn"
		duration_toggle_btn.custom_minimum_size = Vector2(100, 32)
		duration_toggle_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		duration_toggle_btn.focus_mode = Control.FOCUS_NONE
		duration_toggle_btn.add_theme_font_size_override("font_size", 13)
		duration_toggle_btn.tooltip_text = "Toggle loop duration between 15s (Fast) and 30s (Standard). Available in Chambers 1-5 only."
		duration_toggle_btn.pressed.connect(_on_duration_toggle_pressed)
		var timer_container := get_node_or_null("TopBar/Margin/HBox/TimerContainer")
		if timer_container:
			var idx := timer_container.get_index()
			container.add_child(duration_toggle_btn)
			container.move_child(duration_toggle_btn, idx + 1)
		else:
			container.add_child(duration_toggle_btn)

func _update_duration_toggle_ui() -> void:
	_ensure_duration_toggle_button()
	if not duration_toggle_btn:
		return
		
	if current_level_number >= 1 and current_level_number <= 5:
		duration_toggle_btn.visible = true
		var is_fast: bool = SaveManager.is_fast_early_loops() if SaveManager else false
		if is_fast:
			duration_toggle_btn.text = "⚡ 15s LOOP"
			duration_toggle_btn.modulate = Color(0.2, 0.95, 1.0)
		else:
			duration_toggle_btn.text = "⏱ 30s LOOP"
			duration_toggle_btn.modulate = Color(0.85, 0.85, 0.9)
	else:
		duration_toggle_btn.visible = false

func _on_duration_toggle_pressed() -> void:
	if current_level_number < 1 or current_level_number > 5:
		return
	SoundManager.play_sfx("click")
	var new_fast: bool = not (SaveManager.is_fast_early_loops() if SaveManager else false)
	if SaveManager:
		SaveManager.set_fast_early_loops(new_fast)
		
	var lm = get_tree().get_first_node_in_group("loop_manager") as LoopManager
	if lm:
		lm.set_loop_duration(15.0 if new_fast else 30.0)
		
	_update_duration_toggle_ui()
	var mode_text := "15 SECONDS (FAST PACING)" if new_fast else "30 SECONDS (STANDARD)"
	show_temporary_notice("CHAMBER LOOP PACING: " + mode_text)

func show_temporary_notice(msg: String) -> void:
	var label := get_node_or_null("BottomBar/Margin/ControlsLabel") as Label
	if label:
		var orig_text := label.text
		label.text = "✦ " + msg.to_upper()
		label.modulate = Color(0.2, 0.95, 1.0)
		var t := create_tween()
		t.tween_interval(2.5)
		t.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
		t.finished.connect(func():
			if is_instance_valid(label):
				label.text = orig_text
		)

func set_rewind_available(available: bool) -> void:
	var label := get_node_or_null("BottomBar/Margin/ControlsLabel") as Label
	if label:
		if available:
			label.text = "[WASD / Arrows] Move   |   [E / Space] Interact   |   [R] Rewind Loop   |   [C] Clear Echoes & Reset   |   [ESC] Pause"
		elif current_level_number <= 5:
			label.text = "[WASD / Arrows] Move   |   [E / Space] Interact   |   [T / ⚡] 15s/30s Loop   |   [C] Clear Echoes & Reset   |   [ESC] Pause"
		else:
			label.text = "[WASD / Arrows] Move   |   [E / Space] Interact   |   [R] Locked (Sector 1)   |   [C] Clear Echoes & Reset   |   [ESC] Pause"

func show_rewind_locked_notice(msg: String) -> void:
	var label := get_node_or_null("BottomBar/Margin/ControlsLabel") as Label
	if label:
		var orig_text := label.text
		label.text = "⚠ " + msg.to_upper()
		label.modulate = Color(1.0, 0.35, 0.35)
		var t := create_tween()
		t.tween_interval(2.0)
		t.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
		t.finished.connect(func():
			if is_instance_valid(label):
				label.text = orig_text
		)

func update_time(current_time: float, max_duration: float) -> void:
	var remaining: float = maxf(0.0, max_duration - current_time)
	if timer_label:
		timer_label.text = "%04.1fs" % remaining
	if timer_bar:
		timer_bar.max_value = max_duration
		timer_bar.value = remaining
	if timeline_widget:
		timeline_widget.set_timeline(current_time, max_duration)
		
	# Dynamic color and audio urgency feedback
	if remaining <= 5.0:
		timer_label.modulate = Color(1.0, 0.25, 0.25)
		var current_sec := int(remaining)
		if current_sec != _last_alarm_sec and current_sec > 0:
			_last_alarm_sec = current_sec
			SoundManager.play_sfx("tick", 1.4)
	elif remaining <= 10.0:
		timer_label.modulate = Color(1.0, 0.8, 0.2)
		_last_alarm_sec = -1
	else:
		timer_label.modulate = Color(0.2, 0.9, 1.0)
		_last_alarm_sec = -1

func set_timeline_tracks(tracks: Array) -> void:
	if timeline_widget:
		timeline_widget.set_tracks(tracks)

func update_loop_number(loop_num: int) -> void:
	if loop_label:
		loop_label.text = "LOOP #%02d" % loop_num

func update_echo_count(count: int, max_echoes: int = 5) -> void:
	if echo_label:
		echo_label.text = "ECHOES: %d / %d" % [count, max_echoes]

var _is_interception_active: bool = false
var _flash_tween: Tween = null

func trigger_rewind_effect() -> void:
	if not rewind_flash:
		return
	if _is_interception_active:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	rewind_flash.color = Color(0.3, 0.85, 1.0, 0.6)
	_flash_tween = create_tween()
	_flash_tween.tween_property(rewind_flash, "color", Color(0.2, 0.8, 1.0, 0.0), 0.5)

func trigger_interception_flash() -> void:
	if not rewind_flash:
		return
	_is_interception_active = true
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	rewind_flash.color = Color(1.0, 0.15, 0.2, 0.75)
	_flash_tween = create_tween()
	_flash_tween.tween_property(rewind_flash, "color", Color(1.0, 0.1, 0.2, 0.0), 0.65)
	_flash_tween.finished.connect(func(): _is_interception_active = false)

func _on_narrative_opened(log_data: Dictionary) -> void:
	if not terminal_modal:
		return
	terminal_title.text = log_data.get("title", "TERMINAL LOG")
	terminal_meta.text = "%s  |  %s" % [log_data.get("author", ""), log_data.get("timestamp", "")]
	terminal_content.text = log_data.get("content", "")
	terminal_modal.visible = true

func _on_narrative_closed() -> void:
	if terminal_modal:
		terminal_modal.visible = false

func _on_close_terminal_pressed() -> void:
	GameManager.close_narrative()

func _unhandled_input(event: InputEvent) -> void:
	if terminal_modal and terminal_modal.visible:
		if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
			GameManager.close_narrative()
			get_viewport().set_input_as_handled()

func _on_chamber_cleared(data: Dictionary) -> void:
	if not chamber_clear_modal:
		return
	get_tree().paused = true
	var lvl: int = data.get("level_index", 1)
	var loops: int = data.get("loop_count", 1)
	var time: float = data.get("elapsed_time", 0.0)
	var par: int = data.get("par_loops", 2)
	var is_new: bool = data.get("is_new_record", false)
	
	chamber_clear_modal.display_results(lvl, loops, time, par, is_new)

func _on_modal_next() -> void:
	get_tree().paused = false
	GameManager.advance_to_next_level()

func _on_modal_retry() -> void:
	get_tree().paused = false
	GameManager.restart_current_level()

func _on_modal_select() -> void:
	get_tree().paused = false
	GameManager.open_level_select()
