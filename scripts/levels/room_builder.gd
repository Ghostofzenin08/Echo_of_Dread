class_name RoomBuilder
extends Node2D

@export var room_size: Vector2 = Vector2(1280, 720)
@export var floor_color: Color = Color(0.08, 0.1, 0.14, 1.0)
@export var grid_line_color: Color = Color(0.12, 0.16, 0.22, 1.0)
@export var wall_color: Color = Color(0.18, 0.22, 0.3, 1.0)
@export var wall_border_color: Color = Color(0.35, 0.45, 0.6, 1.0)

# Interior wall rectangles in room local space: Array[Rect2]
@export var interior_walls: Array[Rect2] = []

var _static_body: StaticBody2D = null

func _ready() -> void:
	z_index = -10
	_build_collision()
	queue_redraw()

func rebuild_collision() -> void:
	if _static_body and is_instance_valid(_static_body):
		remove_child(_static_body)
		_static_body.queue_free()
		_static_body = null
	_build_collision()
	queue_redraw()

func _build_collision() -> void:
	_static_body = StaticBody2D.new()
	_static_body.collision_layer = 1 # World
	_static_body.collision_mask = 6  # Player & Echoes
	add_child(_static_body)
	
	# Perimeter walls (thickness = 32px)
	var t := 32.0
	_add_wall_shape(Rect2(0, 0, room_size.x, t))                       # Top wall
	_add_wall_shape(Rect2(0, room_size.y - t, room_size.x, t))         # Bottom wall
	_add_wall_shape(Rect2(0, t, t, room_size.y - (2 * t)))             # Left wall
	_add_wall_shape(Rect2(room_size.x - t, t, t, room_size.y - (2 * t))) # Right wall
	
	# Interior walls
	for wall_rect in interior_walls:
		_add_wall_shape(wall_rect)

func _add_wall_shape(rect: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = rect.size
	shape.shape = rect_shape
	shape.position = rect.position + rect.size * 0.5
	_static_body.add_child(shape)

func _draw() -> void:
	# Outer perimeter foundation & abyss border (prevents void leaks during screen shake / lookahead)
	draw_rect(Rect2(-128, -128, room_size.x + 256, room_size.y + 256), Color(0.03, 0.04, 0.06, 1.0), true)
	
	# Floor background
	draw_rect(Rect2(Vector2.ZERO, room_size), floor_color, true)
	
	# Grid lines (64x64 tiles)
	var step := 64.0
	var x := 0.0
	while x <= room_size.x:
		draw_line(Vector2(x, 0), Vector2(x, room_size.y), grid_line_color, 1.0)
		x += step
		
	var y := 0.0
	while y <= room_size.y:
		draw_line(Vector2(0, y), Vector2(room_size.x, y), grid_line_color, 1.0)
		y += step
		
	# Draw perimeter walls
	var t := 32.0
	_draw_wall_rect(Rect2(0, 0, room_size.x, t))
	_draw_wall_rect(Rect2(0, room_size.y - t, room_size.x, t))
	_draw_wall_rect(Rect2(0, t, t, room_size.y - (2 * t)))
	_draw_wall_rect(Rect2(room_size.x - t, t, t, room_size.y - (2 * t)))
	
	# Draw interior walls
	for wall_rect in interior_walls:
		_draw_wall_rect(wall_rect)

func _draw_wall_rect(rect: Rect2) -> void:
	draw_rect(rect, wall_color, true)
	draw_rect(rect, wall_border_color, false, 2.0)
	
	# Subtle metallic rivet / corner detail
	if rect.size.x >= 16 and rect.size.y >= 16:
		draw_circle(rect.position + Vector2(6, 6), 2.0, wall_border_color)
		draw_circle(rect.position + rect.size - Vector2(6, 6), 2.0, wall_border_color)
