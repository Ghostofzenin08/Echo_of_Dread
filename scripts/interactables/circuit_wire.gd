class_name CircuitWire
extends Node2D

@export var is_powered: bool = false
@export var wire_points: PackedVector2Array = []
@export var powered_color: Color = Color(0.2, 0.9, 1.0, 0.95)
@export var unpowered_color: Color = Color(0.2, 0.25, 0.35, 0.6)

var _pulse_timer: float = 0.0

func _ready() -> void:
	add_to_group("resettable")
	z_index = -1
	queue_redraw()

func reset_state() -> void:
	is_powered = false
	_pulse_timer = 0.0
	queue_redraw()

func set_powered(state: bool) -> void:
	if is_powered != state:
		is_powered = state
		queue_redraw()

func _process(delta: float) -> void:
	if is_powered:
		_pulse_timer += delta * 4.0
		queue_redraw()

func _draw() -> void:
	if wire_points.size() < 2:
		return
		
	# Draw wire outline
	draw_polyline(wire_points, Color(0.05, 0.06, 0.08, 0.8), 5.0)
	
	# Draw core line
	var col := unpowered_color
	if is_powered:
		var brightness := 0.8 + 0.2 * sin(_pulse_timer)
		col = powered_color * brightness
		draw_polyline(wire_points, col * 0.5, 6.0)
		
	draw_polyline(wire_points, col, 2.5)
	
	# Node junction dots at every point
	for pt in wire_points:
		draw_circle(pt, 3.0, col)
