class_name TactileCamera
extends Camera2D

# TactileCamera: Procedural trauma-based screen shake, velocity look-ahead,
# and smooth damping for AAA game feel in Echo Rooms.

@export var target: Node2D = null
@export var trauma_decay: float = 2.4
@export var max_offset: Vector2 = Vector2(18.0, 14.0)
@export var max_roll: float = 0.04 # Maximum rotation in radians
@export var look_ahead_factor: float = 0.22 # Velocity lookahead
@export var look_ahead_max: float = 45.0
@export var damping: float = 7.0

var trauma: float = 0.0 # Range: [0.0, 1.0]
var _time: float = 0.0
var _current_look_ahead: Vector2 = Vector2.ZERO
var _room_bounds: Rect2 = Rect2(0, 0, 1280, 720)

func _ready() -> void:
	position_smoothing_enabled = false
	global_position = _room_bounds.position + _room_bounds.size * 0.5

func add_trauma(amount: float) -> void:
	if SaveManager and not SaveManager.get_setting("screen_shake", true):
		return
	trauma = clampf(trauma + amount, 0.0, 1.0)

func set_target(new_target: Node2D) -> void:
	target = new_target

func set_room_bounds(bounds: Rect2) -> void:
	_room_bounds = bounds

func _process(delta: float) -> void:
	_time += delta * 36.0
	
	# Trauma decay & screen shake calculation
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - trauma_decay * delta)
		var shake := trauma * trauma # Non-linear quadratic curve for punchy feel
		
		# Multi-harmonic procedural sine waves for organic, non-repeating shake
		var shake_x := (sin(_time * 1.0) * 0.65 + sin(_time * 2.37) * 0.35) * max_offset.x * shake
		var shake_y := (cos(_time * 1.33) * 0.65 + cos(_time * 2.81) * 0.35) * max_offset.y * shake
		var shake_rot := sin(_time * 1.71) * max_roll * shake
		
		offset = Vector2(shake_x, shake_y)
		rotation = shake_rot
	else:
		offset = Vector2.ZERO
		rotation = 0.0
		
	# Dynamic velocity look-ahead and smooth tracking
	var center := _room_bounds.position + _room_bounds.size * 0.5
	if target and is_instance_valid(target):
		var target_vel: Vector2 = Vector2.ZERO
		if target is CharacterBody2D:
			target_vel = target.velocity
		elif "velocity" in target:
			target_vel = target.velocity
		elif target.has_meta("velocity"):
			target_vel = target.get_meta("velocity")
		var desired_look_ahead := (target_vel * look_ahead_factor).limit_length(look_ahead_max)
		_current_look_ahead = _current_look_ahead.lerp(desired_look_ahead, damping * delta)
		
		# Chamber viewport tracking: responsive bias towards velocity look-ahead
		var desired_pos := center + _current_look_ahead
		global_position = global_position.lerp(desired_pos, damping * delta)
	else:
		global_position = global_position.lerp(center, damping * delta)
