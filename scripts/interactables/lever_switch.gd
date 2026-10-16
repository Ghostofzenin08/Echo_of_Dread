class_name LeverSwitch
extends Area2D

signal state_changed(is_active: bool)

@export var switch_id: String = "switch_1"
@export var is_active: bool = false
@export var initial_active: bool = false
@export var active_color: Color = Color(0.2, 1.0, 0.4, 1.0)
@export var inactive_color: Color = Color(1.0, 0.25, 0.25, 0.8)

const InteractionPromptClass = preload("res://scripts/ui/interaction_prompt.gd")

var is_hovered: bool = false
var interaction_prompt: Node2D = null

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("resettable")
	collision_layer = 8
	collision_mask = 2 | 4
	
	interaction_prompt = InteractionPromptClass.new()
	interaction_prompt.name = "InteractionPrompt"
	add_child(interaction_prompt)
	
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	queue_redraw()

func show_prompt() -> void:
	if interaction_prompt:
		interaction_prompt.show_prompt()

func hide_prompt() -> void:
	if interaction_prompt:
		interaction_prompt.hide_prompt()

func is_prompt_visible() -> bool:
	return interaction_prompt != null and interaction_prompt.is_prompt_visible()

func reset_state() -> void:
	is_active = initial_active
	is_hovered = false
	hide_prompt()
	state_changed.emit(is_active)
	queue_redraw()

func interact(_actor: Node2D = null) -> void:
	is_active = not is_active
	var bus_name := "Echoes" if (_actor is Echo) else "SFX"
	if is_active:
		SoundManager.play_sfx_at_position("switch_on", global_position, 1.0, 0.0, bus_name)
	else:
		SoundManager.play_sfx_at_position("switch_off", global_position, 1.0, 0.0, bus_name)
	state_changed.emit(is_active)
	queue_redraw()

func _draw() -> void:
	# Console housing
	var base_rect := Rect2(-18, -18, 36, 36)
	draw_rect(base_rect, Color(0.1, 0.12, 0.16, 0.95), true)
	draw_rect(base_rect, Color(0.3, 0.35, 0.45, 1.0), false, 2.0)
	
	# Indicator lamp
	var lamp_col := active_color if is_active else inactive_color
	draw_circle(Vector2(0, -8), 5.0, lamp_col)
	
	# Toggle lever
	var lever_pos := Vector2(6, 6) if is_active else Vector2(-6, 6)
	draw_line(Vector2(0, 6), lever_pos, Color(0.8, 0.85, 0.9), 3.0)
	draw_circle(lever_pos, 4.0, lamp_col)
	
	# Hover prompt
	if is_hovered and not is_active:
		draw_arc(Vector2.ZERO, 26.0, 0, TAU, 16, Color(1, 1, 1, 0.4), 1.0)

func _on_area_entered(area: Area2D) -> void:
	if area.name == "InteractionDetector" or (area.get_parent() is Player):
		is_hovered = true
		show_prompt()
		queue_redraw()

func _on_area_exited(area: Area2D) -> void:
	if area.name == "InteractionDetector" or (area.get_parent() is Player):
		is_hovered = false
		hide_prompt()
		queue_redraw()
