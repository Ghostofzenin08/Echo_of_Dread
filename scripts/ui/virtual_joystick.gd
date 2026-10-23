class_name MobileVirtualJoystick
extends Control

# MobileVirtualJoystick: Silky-smooth on-screen analog joystick for mobile devices.
# Features continuous 360-degree analog strength input and global touch drag tracking.

signal direction_changed(direction: Vector2)

const BASE_DEADZONE: float = 10.0
const BASE_MAX_DISTANCE: float = 90.0
const BASE_RING_RADIUS: float = 85.0
const BASE_THUMB_RADIUS: float = 34.0

@export var deadzone: float = 10.0
@export var max_distance: float = 90.0
@export var ring_radius: float = 85.0
@export var thumb_radius: float = 34.0
@export var smoothing_speed: float = 32.0

@export var base_color: Color = Color(0.01, 0.06, 0.14, 0.65)
@export var ring_color: Color = Color(0.2, 0.85, 1.0, 0.75)
@export var thumb_color: Color = Color(0.18, 0.75, 1.0, 0.85)

var radius_scale: float = 1.0
var sensitivity: float = 1.0

var _touch_id: int = -1
var _center_pos: Vector2 = Vector2.ZERO
var _target_pos: Vector2 = Vector2.ZERO
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
	apply_settings()
	if SaveManager and not SaveManager.settings_changed.is_connected(apply_settings):
		SaveManager.settings_changed.connect(apply_settings)
	resized.connect(_on_resized)

func apply_settings() -> void:
	if SaveManager:
		radius_scale = clampf(float(SaveManager.get_setting("joystick_radius_scale", 1.0)), 0.6, 2.0)
		sensitivity = clampf(float(SaveManager.get_setting("movement_sensitivity", 1.0)), 0.5, 2.0)
	else:
		radius_scale = 1.0
		sensitivity = 1.0
		
	deadzone = BASE_DEADZONE * radius_scale
	max_distance = BASE_MAX_DISTANCE * radius_scale
	ring_radius = BASE_RING_RADIUS * radius_scale
	thumb_radius = BASE_THUMB_RADIUS * radius_scale
	
	var min_dim := (max_distance + thumb_radius) * 2.0 + 16.0
	custom_minimum_size = Vector2(min_dim, min_dim)
	_update_center()

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
				_update_stick(event.position, true)
		elif event.index == _touch_id:
			_reset_stick()
		accept_event()
		return
		
	if event is InputEventScreenDrag and event.index == _touch_id:
		_update_stick(event.position, false)
		accept_event()
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_active = true
			_touch_id = 999
			_update_stick(event.position, true)
		else:
			_reset_stick()
		accept_event()
		return
		
	if event is InputEventMouseMotion and is_active and _touch_id == 999:
		_update_stick(event.position, false)
		accept_event()
		return

func _input(event: InputEvent) -> void:
	if not is_active:
		return
		
	# Global tracking so joystick doesn't lose touch when dragging outside bounding rect
	if event is InputEventScreenDrag and event.index == _touch_id:
		var local_pos: Vector2 = get_global_transform().affine_inverse() * event.position
		_update_stick(local_pos, false)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.index == _touch_id and not event.pressed:
		_reset_stick()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _touch_id == 999:
		var local_pos: Vector2 = get_global_transform().affine_inverse() * event.position
		_update_stick(local_pos, false)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _touch_id == 999:
		_reset_stick()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if is_active:
		var target_diff := _target_pos - _center_pos
		var dist := target_diff.length()
		if dist > max_distance:
			target_diff = target_diff.normalized() * max_distance
		var desired_pos := _center_pos + target_diff
		_stick_pos = _stick_pos.lerp(desired_pos, clampf(smoothing_speed * delta, 0.0, 1.0))
		_recalculate_output()
	elif _stick_pos != _center_pos:
		_stick_pos = _stick_pos.lerp(_center_pos, clampf(smoothing_speed * delta, 0.0, 1.0))
		if _stick_pos.distance_squared_to(_center_pos) < 0.5:
			_stick_pos = _center_pos
		queue_redraw()

func _update_stick(pos: Vector2, snap: bool = true) -> void:
	_target_pos = pos
	if snap or not is_inside_tree():
		var diff := pos - _center_pos
		var dist := diff.length()
		if dist > max_distance:
			diff = diff.normalized() * max_distance
		_stick_pos = _center_pos + diff
		_recalculate_output()

func _recalculate_output() -> void:
	var cur_diff := _stick_pos - _center_pos
	var cur_dist := cur_diff.length()
	if cur_dist < deadzone:
		_output_vector = Vector2.ZERO
	else:
		var norm_dist := ((cur_dist - deadzone) / (max_distance - deadzone)) * sensitivity
		_output_vector = cur_diff.normalized() * clampf(norm_dist, 0.0, 1.0)
		
	direction_changed.emit(_output_vector)
	_sync_input_actions()
	queue_redraw()

func _sync_input_actions() -> void:
	# Provide true analog strength (0.0 to 1.0) for ultra-smooth movement
	var left_strength := clampf(-_output_vector.x, 0.0, 1.0)
	var right_strength := clampf(_output_vector.x, 0.0, 1.0)
	var up_strength := clampf(-_output_vector.y, 0.0, 1.0)
	var down_strength := clampf(_output_vector.y, 0.0, 1.0)
	
	_update_action("move_left", left_strength)
	_update_action("move_right", right_strength)
	_update_action("move_up", up_strength)
	_update_action("move_down", down_strength)

func _update_action(action: String, strength: float) -> void:
	if strength > 0.02:
		_pressed_actions[action] = true
		Input.action_press(action, strength)
	else:
		if _pressed_actions.get(action, false) or Input.is_action_pressed(action):
			_pressed_actions[action] = false
			Input.action_release(action)

func _reset_stick() -> void:
	is_active = false
	_touch_id = -1
	_target_pos = _center_pos
	_stick_pos = _center_pos
	_output_vector = Vector2.ZERO
	direction_changed.emit(Vector2.ZERO)
	
	for action in _pressed_actions.keys():
		if _pressed_actions[action] or Input.is_action_pressed(action):
			_pressed_actions[action] = false
			Input.action_release(action)
			
	queue_redraw()

func _exit_tree() -> void:
	_reset_stick()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_reset_stick()

func get_direction() -> Vector2:
	return _output_vector

func _draw() -> void:
	# Outer semi-transparent bounding base
	draw_circle(_center_pos, ring_radius, base_color)
	
	# High-tech glowing perimeter ring
	draw_arc(_center_pos, ring_radius, 0, TAU, 48, ring_color, 2.5)
	
	# Cardinal orientation notches
	var tick_len := 10.0
	draw_line(_center_pos - Vector2(ring_radius, 0), _center_pos - Vector2(ring_radius - tick_len, 0), ring_color, 2.0)
	draw_line(_center_pos + Vector2(ring_radius - tick_len, 0), _center_pos + Vector2(ring_radius, 0), ring_color, 2.0)
	draw_line(_center_pos - Vector2(0, ring_radius), _center_pos - Vector2(0, ring_radius - tick_len), ring_color, 2.0)
	draw_line(_center_pos + Vector2(0, ring_radius - tick_len), _center_pos + Vector2(0, ring_radius), ring_color, 2.0)
	
	# Deadzone marker
	draw_arc(_center_pos, deadzone, 0, TAU, 24, Color(ring_color.r, ring_color.g, ring_color.b, 0.3), 1.0)
	
	# Thumb stick
	var cur_thumb_color := thumb_color
	if is_active:
		cur_thumb_color = Color(0.3, 0.95, 1.0, 0.95)
		# Connecting line from center to thumb
		draw_line(_center_pos, _stick_pos, Color(ring_color.r, ring_color.g, ring_color.b, 0.5), 2.5)
		
	draw_circle(_stick_pos, thumb_radius, cur_thumb_color)
	draw_arc(_stick_pos, thumb_radius, 0, TAU, 32, Color.WHITE, 1.5)
	draw_circle(_stick_pos, 5.0, Color.WHITE)
