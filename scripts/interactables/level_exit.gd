class_name LevelExit
extends Area2D

signal exit_reached

@export var is_unlocked: bool = true
@export var portal_color: Color = Color(0.2, 0.9, 1.0, 1.0)

var _rotation_angle: float = 0.0
var _has_triggered: bool = false

func _ready() -> void:
	add_to_group("resettable")
	collision_layer = 8
	collision_mask = 2 # Only player triggers level exit
	body_entered.connect(_on_body_entered)
	queue_redraw()

func reset_state() -> void:
	_has_triggered = false
	queue_redraw()

func _process(delta: float) -> void:
	if is_unlocked:
		_rotation_angle += delta * 1.8
		queue_redraw()

func _draw() -> void:
	# Outer containment ring
	draw_circle(Vector2.ZERO, 30.0, Color(0.08, 0.1, 0.15, 0.9))
	draw_arc(Vector2.ZERO, 30.0, 0, TAU, 32, Color(0.3, 0.4, 0.55), 2.0)
	
	if is_unlocked:
		# Rotating energy glyph
		var pts: PackedVector2Array = []
		var count := 4
		for i in range(count):
			var a := _rotation_angle + (float(i) * TAU / float(count))
			pts.append(Vector2(cos(a), sin(a)) * 20.0)
		pts.append(pts[0])
		draw_polyline(pts, portal_color, 2.5)
		draw_circle(Vector2.ZERO, 10.0, portal_color * 0.8)
	else:
		draw_circle(Vector2.ZERO, 12.0, Color(0.5, 0.2, 0.2, 0.8))

func _on_body_entered(body: Node2D) -> void:
	if _has_triggered:
		return
	if is_unlocked and body is Player:
		_has_triggered = true
		exit_reached.emit()
		var loops := 1
		var time := 0.0
		var parent_level := _find_parent_level()
		if parent_level and "loop_manager" in parent_level and parent_level.loop_manager:
			loops = parent_level.loop_manager.current_loop_number
			time = parent_level.loop_manager.current_loop_time
		GameManager.complete_level(loops, time)

func _find_parent_level() -> Node:
	var curr: Node = get_parent()
	while curr:
		if curr.has_node("LoopManager"):
			return curr
		curr = curr.get_parent()
	return null
