class_name InteractionPrompt
extends Node2D

# InteractionPrompt: Subtle in-world holographic floating prompt with smooth fade in/out
# and gentle sci-fi pulsating breathing animation.

@export var prompt_text: String = "[E] INTERACT"
@export var prompt_color: Color = Color(0.35, 0.9, 1.0, 1.0)
@export var float_offset_y: float = -34.0

var label: Label = null
var _tween: Tween = null
var _pulse_timer: float = 0.0
var _is_showing: bool = false

func _init() -> void:
	z_index = 20
	label = Label.new()
	label.name = "PromptLabel"
	label.text = prompt_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-50, float_offset_y)
	label.size = Vector2(100, 20)
	label.pivot_offset = Vector2(50, 10)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", prompt_color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.15, 0.3, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.modulate.a = 0.0
	label.visible = false
	add_child(label)

func _ready() -> void:
	if label and not label.is_inside_tree():
		add_child(label)

func _process(delta: float) -> void:
	if label and label.visible and label.modulate.a > 0.01:
		_pulse_timer += delta * 3.5
		label.position.y = float_offset_y + sin(_pulse_timer) * 1.5
		var pulse := 1.0 + 0.04 * sin(_pulse_timer)
		label.scale = Vector2(pulse, pulse)
		var glow := Color(prompt_color.r, prompt_color.g + 0.06 * sin(_pulse_timer), prompt_color.b, label.modulate.a)
		label.add_theme_color_override("font_color", glow)

func show_prompt() -> void:
	_is_showing = true
	if not label:
		return
	label.visible = true
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(label, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func hide_prompt() -> void:
	_is_showing = false
	if not label:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(label, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.finished.connect(func():
		if not _is_showing and label:
			label.visible = false
	)

func set_prompt_visible(p_visible: bool) -> void:
	if p_visible:
		show_prompt()
	else:
		hide_prompt()

func is_prompt_visible() -> bool:
	return label != null and label.visible and label.modulate.a > 0.05
