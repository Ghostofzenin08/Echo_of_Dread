class_name MobileVirtualJoystick
extends Control

# MobileVirtualJoystick: High-responsiveness on-screen analog/digital joystick for mobile devices.
# Translates multi-touch drag gestures directly into Godot Input actions:
# 'move_left', 'move_right', 'move_up', 'move_down'.

signal direction_changed(direction: Vector2)

@export var deadzone: float = 12.0
@export var max_distance: float = 65.0
@export var ring_radius: float = 60.0
@export var thumb_radius: float = 26.0

@export var base_color: Color = Color(0.06, 0.10, 0.16, 0.55)
@export var ring_color: Color = Color(0.2, 0.85, 1.0, 0.65)
@export var thumb_color: Color = Color(0.15, 0.65, 0.95, 0.85)

var _touch_id: int = -1
var _center_pos: Vector2 = Vector2.ZERO
var _stick_pos: Vector2 = Vector2.ZERO
var _output_vector: Vector2 = Vector2.ZERO
var is_active: bool = false

var _pressed_actions: Dictionary = {
	"move_left": false,
	"move_right": false,
	"move_up": false,
	"move_down": false
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(160, 160)
	_update_center()
	resized.connect(_on_resized)

func _on_resized() -> void:
	_update_center()

func _update_center() -> void:
	_center_pos = size * 0.5
	if not is_active:
		_stick_pos = _center_pos
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if not is_active:
				is_active = true
				_touch_id = event.index
				_update_stick(event.position)
		elif event.index == _touch_id:
			_reset_stick()
		accept_event()
		return
		
	if event is InputEventScreenDrag and event.index == _touch_id:
		_update_stick(event.position)
		accept_event()
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_active = true
			_touch_id = 999
			_update_stick(event.position)
		else:
			_reset_stick()
		accept_event()
		return
		
	if event is InputEventMouseMotion and is_active and _touch_id == 999:
		_update_stick(event.position)
		accept_event()
		return

func _update_stick(pos: Vector2) -> void:
	var diff := pos - _center_pos
	var dist := diff.length()
	
	if dist > max_distance:
		diff = diff.normalized() * max_distance
		dist = max_distance
		
	_stick_pos = _center_pos + diff
	
	if dist < deadzone:
		_output_vector = Vector2.ZERO
	else:
		var norm_dist := (dist - deadzone) / (max_distance - deadzone)
		_output_vector = diff.normalized() * norm_dist
		
	direction_changed.emit(_output_vector)
	_sync_input_actions()
	queue_redraw()

func _sync_input_actions() -> void:
	var want_left := _output_vector.x < -0.25
	var want_right := _output_vector.x > 0.25
	var want_up := _output_vector.y < -0.25
	var want_down := _output_vector.y > 0.25
	
	_set_action_state("move_left", want_left)
	_set_action_state("move_right", want_right)
	_set_action_state("move_up", want_up)
	_set_action_state("move_down", want_down)

func _set_action_state(action: String, pressed: bool) -> void:
	if _pressed_actions.get(action, false) != pressed:
		_pressed_actions[action] = pressed
		if pressed:
			Input.action_press(action)
		else:
			Input.action_release(action)

func _reset_stick() -> void:
	is_active = false
	_touch_id = -1
	_stick_pos = _center_pos
	_output_vector = Vector2.ZERO
	direction_changed.emit(Vector2.ZERO)
	
	for action in _pressed_actions.keys():
		if _pressed_actions[action]:
			_pressed_actions[action] = false
			Input.action_release(action)
			
	queue_redraw()

func get_direction() -> Vector2:
	return _output_vector

func _draw() -> void:
	# Outer semi-transparent bounding base
	draw_circle(_center_pos, ring_radius, base_color)
	
	# High-tech glowing perimeter ring
	draw_arc(_center_pos, ring_radius, 0, TAU, 36, ring_color, 2.0)
	
	# Cardinal orientation notches
	var tick_len := 8.0
	draw_line(_center_pos - Vector2(ring_radius, 0), _center_pos - Vector2(ring_radius - tick_len, 0), ring_color, 2.0)
	draw_line(_center_pos + Vector2(ring_radius - tick_len, 0), _center_pos + Vector2(ring_radius, 0), ring_color, 2.0)
	draw_line(_center_pos - Vector2(0, ring_radius), _center_pos - Vector2(0, ring_radius - tick_len), ring_color, 2.0)
	draw_line(_center_pos + Vector2(0, ring_radius - tick_len), _center_pos + Vector2(0, ring_radius), ring_color, 2.0)
	
	# Deadzone marker
	draw_arc(_center_pos, deadzone, 0, TAU, 16, Color(ring_color.r, ring_color.g, ring_color.b, 0.25), 1.0)
	
	# Thumb stick
	var cur_thumb_color := thumb_color
	if is_active:
		cur_thumb_color = Color(0.3, 0.9, 1.0, 0.95)
		# Connecting line from center to thumb
		draw_line(_center_pos, _stick_pos, Color(ring_color.r, ring_color.g, ring_color.b, 0.4), 2.0)
		
	draw_circle(_stick_pos, thumb_radius, cur_thumb_color)
	draw_arc(_stick_pos, thumb_radius, 0, TAU, 24, Color.WHITE, 1.5)
	draw_circle(_stick_pos, 5.0, Color.WHITE)
