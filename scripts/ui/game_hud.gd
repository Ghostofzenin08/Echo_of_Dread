class_name GameHUD
extends CanvasLayer

@onready var chamber_label: Label = $TopBar/Margin/HBox/ChamberLabel
@onready var timer_label: Label = $TopBar/Margin/HBox/TimerContainer/TimerLabel
@onready var timer_bar: ProgressBar = $TopBar/Margin/HBox/TimerContainer/TimerBar
@onready var loop_label: Label = $TopBar/Margin/HBox/LoopLabel
@onready var echo_label: Label = $TopBar/Margin/HBox/EchoLabel

const TimelineWidgetClass = preload("res://scripts/ui/timeline_widget.gd")

@onready var timeline_widget: Control = get_node_or_null("TopBar/Margin/HBox/TimerContainer/TimelineWidget")

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
			
	if rewind_flash:
		rewind_flash.color = Color(0.2, 0.8, 1.0, 0.0)
	if terminal_modal:
		terminal_modal.visible = false
	if terminal_close_btn:
		terminal_close_btn.pressed.connect(_on_close_terminal_pressed)
		
	GameManager.narrative_opened.connect(_on_narrative_opened)
	GameManager.narrative_closed.connect(_on_narrative_closed)

func set_chamber_title(title: String) -> void:
	if chamber_label:
		chamber_label.text = title

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

func trigger_rewind_effect() -> void:
	if not rewind_flash:
		return
	rewind_flash.color = Color(0.3, 0.85, 1.0, 0.6)
	var tween := create_tween()
	tween.tween_property(rewind_flash, "color", Color(0.2, 0.8, 1.0, 0.0), 0.5)

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
