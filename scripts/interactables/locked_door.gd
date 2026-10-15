class_name LockedDoor
extends StaticBody2D

signal door_state_changed(is_open: bool)

enum LogicMode { AND, OR }

@export var door_id: String = "door_1"
@export var logic_mode: LogicMode = LogicMode.AND
@export var is_open: bool = false
@export var connected_triggers: Array[NodePath] = []
@export var door_width: float = 64.0
@export var door_thickness: float = 24.0

var _trigger_states: Dictionary = {}
var _open_ratio: float = 0.0
var _tween: Tween = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("resettable")
	collision_layer = 1
	collision_mask = 2 | 4
	
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect_shape := collision_shape.shape.duplicate() as RectangleShape2D
		rect_shape.size = Vector2(door_width, door_thickness)
		collision_shape.shape = rect_shape
	
	for trigger_path in connected_triggers:
		var trigger_node := get_node_or_null(trigger_path)
		if trigger_node and trigger_node.has_signal("state_changed"):
			_trigger_states[trigger_node] = false
			trigger_node.state_changed.connect(_on_trigger_state_changed.bind(trigger_node))
			
	_update_door_state(false)
	queue_redraw()

func reset_state() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	for k in _trigger_states.keys():
		_trigger_states[k] = false
	is_open = false
	_open_ratio = 0.0
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	door_state_changed.emit(false)
	queue_redraw()

func register_trigger(trigger_node: Node) -> void:
	if trigger_node and trigger_node.has_signal("state_changed") and not _trigger_states.has(trigger_node):
		_trigger_states[trigger_node] = false
		trigger_node.state_changed.connect(_on_trigger_state_changed.bind(trigger_node))
		_evaluate_state()

func set_trigger_state(trigger_id: Variant, trigger_is_active: bool) -> void:
	_trigger_states[trigger_id] = trigger_is_active
	_evaluate_state()

func _on_trigger_state_changed(is_active: bool, source_trigger: Node) -> void:
	_trigger_states[source_trigger] = is_active
	_evaluate_state()

func _evaluate_state() -> void:
	if _trigger_states.is_empty():
		return
		
	var should_open := false
	if logic_mode == LogicMode.AND:
		should_open = true
		for state in _trigger_states.values():
			if not state:
				should_open = false
				break
	elif logic_mode == LogicMode.OR:
		should_open = false
		for state in _trigger_states.values():
			if state:
				should_open = true
				break
				
	if should_open != is_open:
		_set_open_state(should_open)

func _set_open_state(open: bool) -> void:
	is_open = open
	if is_open:
		SoundManager.play_sfx_at_position("door_open", global_position)
	else:
		SoundManager.play_sfx_at_position("door_close", global_position)
		
	door_state_changed.emit(is_open)
	_animate_transition(is_open)

func _animate_transition(open: bool) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		
	var target_ratio := 1.0 if open else 0.0
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_method(func(val: float):
		_open_ratio = val
		queue_redraw()
	, _open_ratio, target_ratio, 0.45)
	
	_tween.finished.connect(func():
		_update_door_state(is_open)
	)
	
	# If opening, disable collision slightly early so player isn't blocked by a hairline gap
	if open:
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
	else:
		if collision_shape:
			collision_shape.set_deferred("disabled", false)

func _update_door_state(open: bool) -> void:
	_open_ratio = 1.0 if open else 0.0
	if collision_shape:
		collision_shape.set_deferred("disabled", open)
	queue_redraw()

func _draw() -> void:
	var half_w := door_width * 0.5
	var half_h := door_thickness * 0.5
	
	# Outer door frame
	var frame_rect := Rect2(-half_w - 6, -half_h - 4, door_width + 12, door_thickness + 8)
	draw_rect(frame_rect, Color(0.12, 0.15, 0.2, 1.0), true)
	draw_rect(frame_rect, Color(0.3, 0.35, 0.45, 1.0), false, 2.0)
	
	# Status indicator lights on the frame
	var led_color := Color(0.2, 1.0, 0.4) if is_open else Color(1.0, 0.25, 0.25)
	draw_circle(Vector2(-half_w - 3, 0), 3.0, led_color)
	draw_circle(Vector2(half_w + 3, 0), 3.0, led_color)
	
	# Sliding door panels (split in middle and retract into frame)
	var panel_width := half_w
	var slide_offset := _open_ratio * panel_width
	
	# Left panel
	var left_rect := Rect2(-half_w - slide_offset, -half_h, panel_width, door_thickness)
	draw_rect(left_rect, Color(0.2, 0.25, 0.32, 1.0), true)
	draw_rect(left_rect, Color(0.4, 0.5, 0.65, 1.0), false, 1.5)
	
	# Right panel
	var right_rect := Rect2(slide_offset, -half_h, panel_width, door_thickness)
	draw_rect(right_rect, Color(0.2, 0.25, 0.32, 1.0), true)
	draw_rect(right_rect, Color(0.4, 0.5, 0.65, 1.0), false, 1.5)
	
	# Chevrons / caution stripes on panels when closed
	if _open_ratio < 0.5:
		draw_line(Vector2(-10 - slide_offset, -half_h + 4), Vector2(-10 - slide_offset, half_h - 4), led_color, 2.0)
		draw_line(Vector2(10 + slide_offset, -half_h + 4), Vector2(10 + slide_offset, half_h - 4), led_color, 2.0)
