class_name TerminalLog
extends Area2D

@export var log_id: String = "log_01"
@export var terminal_color: Color = Color(0.2, 0.9, 0.5, 1.0) # Green CRT phosphors

const InteractionPromptClass = preload("res://scripts/ui/interaction_prompt.gd")

var is_hovered: bool = false
var _blink_timer: float = 0.0
var interaction_prompt: Node2D = null

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 8
	collision_mask = 2 | 4
	
	interaction_prompt = InteractionPromptClass.new()
	interaction_prompt.name = "InteractionPrompt"
	add_child(interaction_prompt)
	
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	if GameManager:
		GameManager.narrative_opened.connect(func(_data): hide_prompt())
		GameManager.narrative_closed.connect(func(): if is_hovered: show_prompt())
		
	queue_redraw()

func show_prompt() -> void:
	if interaction_prompt and not GameManager.is_narrative_open:
		interaction_prompt.show_prompt()

func hide_prompt() -> void:
	if interaction_prompt:
		interaction_prompt.hide_prompt()

func is_prompt_visible() -> bool:
	return interaction_prompt != null and interaction_prompt.is_prompt_visible()

func interact(actor: Node2D) -> void:
	if actor is Player:
		GameManager.open_narrative(log_id)

func _process(delta: float) -> void:
	_blink_timer += delta * 2.5
	if is_hovered:
		queue_redraw()

func _draw() -> void:
	# Terminal desk & chassis
	var desk_rect := Rect2(-20, -16, 40, 32)
	draw_rect(desk_rect, Color(0.12, 0.14, 0.18, 0.95), true)
	draw_rect(desk_rect, Color(0.3, 0.35, 0.45, 1.0), false, 2.0)
	
	# Monitor screen
	var screen_rect := Rect2(-14, -12, 28, 20)
	draw_rect(screen_rect, Color(0.04, 0.1, 0.06, 1.0), true)
	draw_rect(screen_rect, terminal_color * 0.7, false, 1.5)
	
	# Glowing cursor / code lines
	var cursor_alpha := 0.5 + 0.5 * sin(_blink_timer)
	var line_col := Color(terminal_color.r, terminal_color.g, terminal_color.b, cursor_alpha)
	draw_line(Vector2(-10, -7), Vector2(6, -7), line_col, 1.5)
	draw_line(Vector2(-10, -2), Vector2(2, -2), line_col, 1.5)
	draw_line(Vector2(-10, 3), Vector2(-4, 3), line_col, 1.5)
	
	# Prompt if player is nearby
	if is_hovered and not GameManager.is_narrative_open:
		draw_arc(Vector2.ZERO, 28.0, 0, TAU, 24, Color(1, 1, 1, 0.5), 1.0)

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
