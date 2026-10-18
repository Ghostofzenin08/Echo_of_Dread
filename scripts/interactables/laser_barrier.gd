class_name LaserBarrier
extends StaticBody2D

signal laser_state_changed(is_active: bool)

@export var is_active: bool = true
@export var initial_active: bool = true
@export var barrier_length: float = 96.0
@export var laser_color: Color = Color(1.0, 0.2, 0.25, 0.9)
@export var emitter_color: Color = Color(0.2, 0.25, 0.35, 1.0)
@export var connected_triggers: Array[NodePath] = []
@export var invert_trigger: bool = true # By default, trigger ON turns laser OFF

var _flicker_phase: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hazard_area: Area2D = $HazardArea

func _ready() -> void:
	add_to_group("resettable")
	collision_layer = 1
	collision_mask = 2 | 4
	
	# Dynamically match collision shapes to barrier_length
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var s := collision_shape.shape.duplicate() as RectangleShape2D
		s.size = Vector2(barrier_length, s.size.y)
		collision_shape.shape = s
		
	if hazard_area and hazard_area.has_node("CollisionShape2D"):
		var h_col: CollisionShape2D = hazard_area.get_node("CollisionShape2D")
		if h_col and h_col.shape is RectangleShape2D:
			var s := h_col.shape.duplicate() as RectangleShape2D
			s.size = Vector2(barrier_length, s.size.y)
			h_col.shape = s
	
	if hazard_area:
		hazard_area.body_entered.connect(_on_hazard_entered)
		
	for trigger_path in connected_triggers:
		var trigger_node := get_node_or_null(trigger_path)
		if trigger_node and trigger_node.has_signal("state_changed"):
			trigger_node.state_changed.connect(_on_trigger_state_changed)
			
	_update_state(is_active)
	queue_redraw()

func reset_state() -> void:
	is_active = initial_active
	_update_state(is_active)
	queue_redraw()

func set_active(active: bool) -> void:
	if is_active != active:
		is_active = active
		_update_state(is_active)

func _update_state(active: bool) -> void:
	if collision_shape:
		collision_shape.set_deferred("disabled", not active)
	if hazard_area:
		hazard_area.set_deferred("monitoring", active)
	laser_state_changed.emit(active)
	queue_redraw()

func _on_trigger_state_changed(trigger_active: bool) -> void:
	var target_active := not trigger_active if invert_trigger else trigger_active
	set_active(target_active)

func _process(delta: float) -> void:
	if is_active:
		_flicker_phase += delta * 12.0
		queue_redraw()

func _draw() -> void:
	var half_len := barrier_length * 0.5
	
	# Emitter posts at both ends
	var p1 := Vector2(-half_len, 0)
	var p2 := Vector2(half_len, 0)
	
	draw_circle(p1, 8.0, emitter_color)
	draw_circle(p2, 8.0, emitter_color)
	
	if is_active:
		var pulse := 0.75 + 0.25 * sin(_flicker_phase)
		var core_col := laser_color * pulse
		core_col.a = 0.95
		
		# Outer laser glow
		draw_line(p1, p2, Color(laser_color.r, laser_color.g, laser_color.b, 0.35), 8.0)
		# Inner beam
		draw_line(p1, p2, core_col, 3.5)
		# Bright core
		draw_line(p1, p2, Color(1, 1, 1, 0.9), 1.0)
		
		# Post lights
		draw_circle(p1, 4.0, laser_color)
		draw_circle(p2, 4.0, laser_color)
	else:
		# Inactive emitter post lights
		draw_circle(p1, 3.0, Color(0.2, 0.8, 0.3, 0.5))
		draw_circle(p2, 3.0, Color(0.2, 0.8, 0.3, 0.5))

func _on_hazard_entered(body: Node2D) -> void:
	if not is_active:
		return
	if body is Player:
		SoundManager.play_sfx_at_position("alarm", global_position)
		# Reset loop on laser contact and shake camera
		var parent_level := _find_parent_level()
		if parent_level:
			if "camera" in parent_level and parent_level.camera:
				parent_level.camera.add_trauma(0.8)
			if "loop_manager" in parent_level and parent_level.loop_manager:
				parent_level.loop_manager.reset_loop()

func _find_parent_level() -> Node:
	var curr: Node = get_parent()
	while curr:
		if curr.has_node("LoopManager"):
			return curr
		curr = curr.get_parent()
	return null
