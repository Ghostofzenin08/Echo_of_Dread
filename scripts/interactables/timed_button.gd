class_name TimedButton
extends Area2D

signal state_changed(is_active: bool)

@export var button_id: String = "timed_btn_1"
@export var active_duration: float = 6.0
@export var active_color: Color = Color(1.0, 0.7, 0.2, 1.0)
@export var inactive_color: Color = Color(0.4, 0.3, 0.15, 0.8)

const InteractionPromptClass = preload("res://scripts/ui/interaction_prompt.gd")

var is_active: bool = false
var time_remaining: float = 0.0
var interaction_prompt: Node2D = null
var _hovering_detectors: Array[Area2D] = []

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
	is_active = false
	time_remaining = 0.0
	_hovering_detectors.clear()
	hide_prompt()
	state_changed.emit(false)
	queue_redraw()

func _is_player_detector(area: Area2D) -> bool:
	if area == null:
		return false
	var parent: Node = area.get_parent()
	if parent is Echo:
		return false
	if parent is Player:
		return true
	if area.name == "InteractionDetector" and not (parent is Echo):
		return true
	return false

func _on_area_entered(area: Area2D) -> void:
	if _is_player_detector(area):
		if not _hovering_detectors.has(area):
			_hovering_detectors.append(area)
		show_prompt()

func _on_area_exited(area: Area2D) -> void:
	if _is_player_detector(area):
		_hovering_detectors.erase(area)
		if _hovering_detectors.is_empty():
			hide_prompt()

func _physics_process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_narrative_open:
		return
	if is_active:
		time_remaining -= delta
		queue_redraw()
		if time_remaining <= 0.0:
			deactivate()

func interact(_actor: Node2D = null) -> void:
	activate(_actor)

func activate(_actor: Node2D = null) -> void:
	time_remaining = active_duration
	if not is_active:
		is_active = true
		var bus_name := "Echoes" if (_actor is Echo) else "SFX"
		SoundManager.play_sfx_at_position("click", global_position, 1.2, 0.0, bus_name)
		state_changed.emit(true)
	queue_redraw()

func deactivate() -> void:
	is_active = false
	time_remaining = 0.0
	SoundManager.play_sfx_at_position("switch_off", global_position, 0.9, 0.0, "SFX")
	state_changed.emit(false)
	queue_redraw()

func _draw() -> void:
	# Circular capacitor button housing
	draw_circle(Vector2.ZERO, 20.0, Color(0.12, 0.12, 0.16, 0.95))
	draw_arc(Vector2.ZERO, 20.0, 0, TAU, 32, Color(0.35, 0.4, 0.5), 2.0)
	
	# Radial fill indicating remaining charge
	if is_active and active_duration > 0.0:
		var pct := time_remaining / active_duration
		var sweep := pct * TAU
		draw_arc(Vector2.ZERO, 15.0, -PI * 0.5, -PI * 0.5 + sweep, 32, active_color, 3.5)
		draw_circle(Vector2.ZERO, 10.0, active_color * 0.7)
	else:
		draw_circle(Vector2.ZERO, 10.0, inactive_color)
