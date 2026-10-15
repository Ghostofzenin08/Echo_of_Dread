class_name PressurePlate
extends Area2D

signal state_changed(is_active: bool)

@export var plate_id: String = "plate_1"
@export var active_color: Color = Color(0.2, 1.0, 0.8, 1.0)
@export var inactive_color: Color = Color(0.2, 0.4, 0.6, 0.7)

var is_pressed: bool = false
var bodies_on_plate: int = 0
var _occupants: Array[Node2D] = []

func _ready() -> void:
	add_to_group("resettable")
	collision_layer = 8 # Layer 4: Interactable
	collision_mask = 2 | 4 # Layer 2 (Player) | Layer 3 (Echoes)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()

func reset_state() -> void:
	_occupants.clear()
	bodies_on_plate = 0
	if is_pressed:
		is_pressed = false
		state_changed.emit(false)
		queue_redraw()

func _draw() -> void:
	# Base plate
	var rect := Rect2(-24, -24, 48, 48)
	var col := active_color if is_pressed else inactive_color
	draw_rect(rect, Color(0.08, 0.1, 0.15, 0.95), true)
	draw_rect(rect, col, false, 2.0)
	
	# Inner sensor pad
	var pad_size := 32.0 if not is_pressed else 28.0
	var pad_rect := Rect2(-pad_size * 0.5, -pad_size * 0.5, pad_size, pad_size)
	draw_rect(pad_rect, col * 0.4, true)
	draw_rect(pad_rect, col, false, 1.5)
	
	# Center glowing glyph
	var center_radius := 6.0 if not is_pressed else 8.0
	draw_circle(Vector2.ZERO, center_radius, col)

func _on_body_entered(body: Node2D) -> void:
	if not _occupants.has(body):
		_occupants.append(body)
	bodies_on_plate = _occupants.size()
	if not is_pressed:
		is_pressed = true
		var bus_name := "Echoes" if (body is Echo) else "SFX"
		SoundManager.play_sfx_at_position("plate_press", global_position, 1.0, 0.0, bus_name)
		state_changed.emit(true)
		queue_redraw()

func _on_body_exited(body: Node2D) -> void:
	_occupants.erase(body)
	_occupants = _occupants.filter(func(b): return is_instance_valid(b))
	bodies_on_plate = _occupants.size()
	if _occupants.is_empty() and is_pressed:
		is_pressed = false
		var bus_name := "Echoes" if (body is Echo) else "SFX"
		SoundManager.play_sfx_at_position("plate_release", global_position, 1.0, 0.0, bus_name)
		state_changed.emit(false)
		queue_redraw()
