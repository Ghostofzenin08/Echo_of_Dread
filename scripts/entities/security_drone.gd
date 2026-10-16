class_name SecurityDrone
extends CharacterBody2D

# SecurityDrone: Autonomous patrolling sentry that detects and intercepts trespassers.
# If a drone detects and catches the player, the timeline collapses and the loop resets.

signal alert_state_changed(is_alert: bool)
signal player_caught_target(drone: CharacterBody2D, player: CharacterBody2D)

enum DroneState { PATROL, PAUSE, CHASE, INVESTIGATE }

@export var patrol_speed: float = 75.0
@export var chase_speed: float = 140.0
@export var detection_radius: float = 190.0
@export var vision_angle_deg: float = 90.0
@export var catch_radius: float = 26.0
@export var waypoint_reach_dist: float = 12.0
@export var pause_duration_at_waypoint: float = 1.0

# Relative or absolute patrol waypoints (Vector2 offsets from spawn)
@export var waypoint_offsets: PackedVector2Array = PackedVector2Array([
	Vector2(0, 0),
	Vector2(200, 0)
])

var current_state: DroneState = DroneState.PATROL
var facing_direction: Vector2 = Vector2.RIGHT

var _initial_global_position: Vector2 = Vector2.ZERO
var _initial_facing_direction: Vector2 = Vector2.RIGHT
var _world_waypoints: Array[Vector2] = []
var _current_waypoint_idx: int = 0
var _pause_timer: float = 0.0
var _investigate_timer: float = 0.0
var _last_known_target_pos: Vector2 = Vector2.ZERO
var _is_catching: bool = false
var _pulse_time: float = 0.0

@onready var visual_root: Node2D = $VisualRoot

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("resettable")
	
	collision_layer = 1 # World / Obstacle layer
	collision_mask = 1  # Collides with walls
	
	_initial_global_position = global_position
	_initial_facing_direction = facing_direction
	
	_rebuild_world_waypoints()
	
	if not visual_root:
		visual_root = Node2D.new()
		visual_root.name = "VisualRoot"
		add_child(visual_root)

func _rebuild_world_waypoints() -> void:
	_world_waypoints.clear()
	if waypoint_offsets.is_empty():
		_world_waypoints.append(_initial_global_position)
	else:
		for offset in waypoint_offsets:
			_world_waypoints.append(_initial_global_position + offset)

func reset_state() -> void:
	global_position = _initial_global_position
	velocity = Vector2.ZERO
	facing_direction = _initial_facing_direction
	current_state = DroneState.PATROL
	_current_waypoint_idx = 0
	_pause_timer = 0.0
	_investigate_timer = 0.0
	_is_catching = false
	alert_state_changed.emit(false)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_narrative_open:
		velocity = Vector2.ZERO
		return
		
	_pulse_time += delta
	
	var target_player := _find_detectable_player()
	
	match current_state:
		DroneState.PATROL:
			_process_patrol(delta, target_player)
		DroneState.PAUSE:
			_process_pause(delta, target_player)
		DroneState.CHASE:
			_process_chase(delta, target_player)
		DroneState.INVESTIGATE:
			_process_investigate(delta, target_player)
			
	move_and_slide()
	
	if visual_root and facing_direction.length_squared() > 0.01:
		visual_root.rotation = facing_direction.angle()
		
	queue_redraw()

func _find_detectable_player() -> Player:
	var candidates: Array[Node] = get_tree().get_nodes_in_group("player")
	if candidates.is_empty():
		for node in get_tree().get_nodes_in_group("resettable"):
			if node is Player:
				candidates.append(node)
				
	var space_state := get_world_2d().direct_space_state if (is_inside_tree() and get_world_2d()) else null
	
	for candidate in candidates:
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
			continue
		var player_candidate := candidate as Player
		if not player_candidate:
			continue
			
		var to_player := player_candidate.global_position - global_position
		var dist := to_player.length()
		if dist > detection_radius:
			continue
			
		var angle_to_player := absf(facing_direction.angle_to(to_player))
		var half_vision_angle := deg_to_rad(vision_angle_deg * 0.5)
		
		if dist > 40.0 and angle_to_player > half_vision_angle:
			continue
			
		if space_state:
			var query := PhysicsRayQueryParameters2D.create(global_position, player_candidate.global_position, 1)
			query.exclude = [self.get_rid()]
			var result := space_state.intersect_ray(query)
			if not result.is_empty() and result.collider != player_candidate:
				# Obstructed by wall or obstacle
				continue
				
		return player_candidate
		
	return null

func _process_patrol(_delta: float, target_player: Player) -> void:
	if target_player:
		_engage_chase(target_player)
		return
		
	if _world_waypoints.is_empty():
		velocity = Vector2.ZERO
		return
		
	var target_dest := _world_waypoints[_current_waypoint_idx]
	var to_dest := target_dest - global_position
	var dist := to_dest.length()
	
	if dist <= waypoint_reach_dist:
		current_state = DroneState.PAUSE
		_pause_timer = pause_duration_at_waypoint
		velocity = Vector2.ZERO
	else:
		facing_direction = to_dest.normalized()
		velocity = facing_direction * patrol_speed

func _process_pause(delta: float, target_player: Player) -> void:
	if target_player:
		_engage_chase(target_player)
		return
		
	velocity = Vector2.ZERO
	_pause_timer -= delta
	if _pause_timer <= 0.0:
		_current_waypoint_idx = (_current_waypoint_idx + 1) % _world_waypoints.size()
		current_state = DroneState.PATROL

func _engage_chase(target_player: Player) -> void:
	if current_state != DroneState.CHASE:
		current_state = DroneState.CHASE
		alert_state_changed.emit(true)
		SoundManager.play_sfx_at_position("drone_alert", global_position, 1.1, -2.0)
		
		# Trigger subtle screen trauma warning
		var camera := get_viewport().get_camera_2d()
		if camera and camera.has_method("add_trauma"):
			camera.add_trauma(0.25)
			
	_last_known_target_pos = target_player.global_position

func _process_chase(_delta: float, target_player: Player) -> void:
	if target_player:
		_last_known_target_pos = target_player.global_position
		var to_player := target_player.global_position - global_position
		var dist := to_player.length()
		
		# Check if caught
		if dist <= catch_radius and not _is_catching:
			_catch_player(target_player)
			return
			
		facing_direction = to_player.normalized()
		velocity = facing_direction * chase_speed
	else:
		# Lost sight, proceed to last known position
		var to_last := _last_known_target_pos - global_position
		if to_last.length() <= waypoint_reach_dist:
			current_state = DroneState.INVESTIGATE
			_investigate_timer = 2.2
			velocity = Vector2.ZERO
		else:
			facing_direction = to_last.normalized()
			velocity = facing_direction * chase_speed

func _process_investigate(delta: float, target_player: Player) -> void:
	if target_player:
		_engage_chase(target_player)
		return
		
	velocity = Vector2.ZERO
	_investigate_timer -= delta
	
	# Sweep scan back and forth
	var sweep_angle := sin(_investigate_timer * 4.0) * 0.8
	facing_direction = Vector2.RIGHT.rotated(sweep_angle).normalized()
	
	if _investigate_timer <= 0.0:
		current_state = DroneState.PATROL
		alert_state_changed.emit(false)

func _catch_player(target_player: Player) -> void:
	_is_catching = true
	velocity = Vector2.ZERO
	
	SoundManager.play_sfx_at_position("player_caught", global_position, 1.0, 3.0)
	SoundManager.play_sfx("alarm", 1.2, 0.0)
	
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.85)
		
	player_caught_target.emit(self, target_player)
	
	# Find loop manager to collapse the timeline
	var loop_mgr: LoopManager = null
	var parent_node := get_parent()
	while parent_node:
		if parent_node.has_node("LoopManager"):
			loop_mgr = parent_node.get_node("LoopManager") as LoopManager
			break
		parent_node = parent_node.get_parent()
		
	if not loop_mgr:
		var loop_managers := get_tree().get_nodes_in_group("loop_manager")
		for candidate in loop_managers:
			if is_instance_valid(candidate) and not candidate.is_queued_for_deletion():
				loop_mgr = candidate as LoopManager
				break
			
	if loop_mgr:
		loop_mgr.reset_loop()

func _draw() -> void:
	var is_alert := (current_state == DroneState.CHASE)
	var cone_color := Color(1.0, 0.15, 0.2, 0.22) if is_alert else Color(0.2, 0.75, 1.0, 0.12)
	var border_color := Color(1.0, 0.25, 0.3, 0.6) if is_alert else Color(0.3, 0.85, 1.0, 0.35)
	
	# 1. Draw detection vision cone
	var half_angle := deg_to_rad(vision_angle_deg * 0.5)
	var num_pts := 16
	var cone_points := PackedVector2Array([Vector2.ZERO])
	
	for i in range(num_pts + 1):
		var t := float(i) / float(num_pts)
		var a := lerpf(-half_angle, half_angle, t)
		var dir := facing_direction.rotated(a)
		cone_points.append(dir * detection_radius)
		
	draw_colored_polygon(cone_points, cone_color)
	
	# Draw perimeter arc
	for i in range(1, cone_points.size() - 1):
		draw_line(cone_points[i], cone_points[i + 1], border_color, 1.5)
	draw_line(Vector2.ZERO, cone_points[1], border_color, 1.0)
	draw_line(Vector2.ZERO, cone_points[cone_points.size() - 1], border_color, 1.0)
	
	# 2. Draw Drone Chassis
	# Drone Body: Sci-fi faceted armor
	var body_color := Color(0.12, 0.16, 0.22, 1.0)
	var rim_color := Color(0.9, 0.2, 0.25, 1.0) if is_alert else Color(0.3, 0.85, 1.0, 1.0)
	
	var rot := facing_direction.angle()
	var forward := Vector2.RIGHT.rotated(rot)
	var right := Vector2.DOWN.rotated(rot)
	
	var p_nose := forward * 16.0
	var p_left_wing := (-forward * 10.0) - (right * 13.0)
	var p_right_wing := (-forward * 10.0) + (right * 13.0)
	var p_tail := -forward * 7.0
	
	var chassis := PackedVector2Array([p_nose, p_right_wing, p_tail, p_left_wing])
	draw_colored_polygon(chassis, body_color)
	draw_polyline(PackedVector2Array([p_nose, p_right_wing, p_tail, p_left_wing, p_nose]), rim_color, 1.8)
	
	# 3. Ocular Sensor / Core Lens
	var eye_color := Color(1.0, 0.1, 0.15, 1.0) if is_alert else Color(0.3, 0.9, 1.0, 1.0)
	var pulse := (sin(_pulse_time * 8.0) + 1.0) * 0.5 if is_alert else (sin(_pulse_time * 3.0) + 1.0) * 0.5
	var eye_radius := lerpf(4.0, 5.5, pulse)
	
	draw_circle(Vector2.ZERO, eye_radius + 2.0, Color(eye_color.r, eye_color.g, eye_color.b, 0.35))
	draw_circle(Vector2.ZERO, eye_radius, eye_color)
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
