class_name Echo
extends CharacterBody2D

signal interaction_performed(target: Node2D)

@export var echo_id: int = 1
@export var echo_color: Color = Color(0.2, 0.8, 1.0, 0.75) # Ghostly cyan default

var recorder: ActionRecorder = null
var current_playback_time: float = 0.0
var nearby_interactables: Array[Area2D] = []
var _last_interact_state: bool = false

@onready var interaction_detector: Area2D = $InteractionDetector
@onready var visual_root: Node2D = $VisualRoot
@onready var echo_label: Label = $EchoLabel

# Holographic motion trail
var trail_line: Line2D = null
var trail_points: Array[Vector2] = []
const MAX_TRAIL_POINTS: int = 18

const ECHO_COLORS: Array[Color] = [
	Color(0.2, 0.85, 1.0, 0.8),  # Cyan
	Color(0.9, 0.35, 1.0, 0.8),  # Magenta
	Color(0.3, 1.0, 0.5, 0.8),   # Emerald
	Color(1.0, 0.8, 0.2, 0.8),   # Amber
	Color(0.4, 0.5, 1.0, 0.8)    # Royal Blue
]

func _ready() -> void:
	collision_layer = 4 # Layer 3: Echoes (bitmask 4)
	collision_mask = 1  # Layer 1: World
	if interaction_detector:
		interaction_detector.area_entered.connect(_on_interactable_entered)
		interaction_detector.area_exited.connect(_on_interactable_exited)
		
	_setup_trail_effect()
	_apply_visual_styling()

func _setup_trail_effect() -> void:
	if trail_line == null:
		trail_line = Line2D.new()
		trail_line.top_level = true
		trail_line.z_index = -1
		trail_line.width = 14.0
		trail_line.joint_mode = Line2D.LINE_JOINT_ROUND
		trail_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		trail_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		
		# Tapering curve from head to tail
		var curve := Curve.new()
		curve.add_point(Vector2(0.0, 1.0))
		curve.add_point(Vector2(1.0, 0.0))
		trail_line.width_curve = curve
		
		add_child(trail_line)
	_update_trail_gradient()

func _update_trail_gradient() -> void:
	if trail_line:
		var grad := Gradient.new()
		grad.set_color(0, Color(echo_color.r, echo_color.g, echo_color.b, 0.45))
		grad.set_color(1, Color(echo_color.r, echo_color.g, echo_color.b, 0.0))
		trail_line.gradient = grad

func setup(p_id: int, p_recorder: ActionRecorder) -> void:
	echo_id = p_id
	recorder = p_recorder
	echo_color = ECHO_COLORS[posmod(echo_id - 1, ECHO_COLORS.size())]
	_apply_visual_styling()
	_update_trail_gradient()

func _apply_visual_styling() -> void:
	if visual_root:
		if visual_root is CharacterVisual:
			visual_root.is_ghost = true
			visual_root.base_body_color = Color(echo_color.r, echo_color.g, echo_color.b, 0.75)
			visual_root.visor_color = echo_color
			visual_root.modulate = Color.WHITE
		else:
			visual_root.modulate = echo_color
	if echo_label:
		echo_label.text = "ECHO #%d" % echo_id
		echo_label.modulate = echo_color

var last_playback_time: float = 0.0

func reset_playback() -> void:
	current_playback_time = 0.0
	last_playback_time = 0.0
	_last_interact_state = false
	nearby_interactables.clear()
	trail_points.clear()
	if trail_line:
		trail_line.clear_points()
	if recorder:
		var frame: Dictionary = recorder.get_frame_at_time(0.0)
		global_position = frame["pos"]

func update_playback(loop_time: float) -> void:
	if not recorder:
		return
		
	var frame: Dictionary = recorder.get_frame_at_time(loop_time)
	global_position = frame["pos"]
	velocity = frame["vel"]
	
	_update_motion_trail()
	
	if visual_root and frame["facing"] != Vector2.ZERO:
		visual_root.rotation = frame["facing"].angle() + PI * 0.5
		
	if not recorder.interaction_times.is_empty():
		var interactions_due := recorder.get_interactions_in_interval(last_playback_time, loop_time)
		for _i in range(interactions_due):
			_perform_playback_interaction()
	else:
		# Fallback: frame-based interaction rising edge
		var is_interacting: bool = frame.get("interact", false)
		if is_interacting and not _last_interact_state:
			_perform_playback_interaction()
		_last_interact_state = is_interacting
		
	last_playback_time = loop_time

func _update_motion_trail() -> void:
	if not is_inside_tree():
		return
		
	if trail_points.is_empty() or global_position.distance_to(trail_points[0]) > 2.0:
		trail_points.push_front(global_position)
		if trail_points.size() > MAX_TRAIL_POINTS:
			trail_points.pop_back()
		if trail_line:
			trail_line.points = PackedVector2Array(trail_points)
	elif velocity.length_squared() < 1.0 and trail_points.size() > 1:
		trail_points.pop_back()
		if trail_line:
			trail_line.points = PackedVector2Array(trail_points)

func _perform_playback_interaction() -> void:
	var target: Area2D = null
	var min_dist := 56.0
	
	# Purge invalid or queued-for-deletion areas
	nearby_interactables = nearby_interactables.filter(func(a): return is_instance_valid(a) and not a.is_queued_for_deletion())
	
	# Check all registered interactables in group
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is Area2D and is_instance_valid(node) and not node.is_queued_for_deletion():
			# Echoes must NEVER trigger narrative lore modals!
			if node is TerminalLog:
				continue
			var dist := global_position.distance_to(node.global_position)
			if dist < min_dist:
				min_dist = dist
				target = node
				
	# If not found via group, check nearby_interactables cache
	if target == null:
		for area in nearby_interactables:
			if is_instance_valid(area) and not area.is_queued_for_deletion() and not (area is TerminalLog):
				var dist := global_position.distance_to(area.global_position)
				if dist < min_dist:
					min_dist = dist
					target = area
					
	if target and target.has_method("interact"):
		target.interact(self)
		interaction_performed.emit(target)
	elif target and target.get_parent() and is_instance_valid(target.get_parent()) and not target.get_parent().is_queued_for_deletion() and target.get_parent().has_method("interact"):
		target.get_parent().interact(self)
		interaction_performed.emit(target.get_parent())

func _on_interactable_entered(area: Area2D) -> void:
	if area.is_in_group("interactable") and not nearby_interactables.has(area):
		nearby_interactables.append(area)

func _on_interactable_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)
