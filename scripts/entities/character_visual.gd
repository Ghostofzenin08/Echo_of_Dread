class_name CharacterVisual
extends Node2D

# CharacterVisual: High-polish visual representation of Player and Echoes.
# Features procedural suit geometry, helmet visor with specular glints,
# and AAA temporal holographic aesthetics for Echoes (interference rings,
# scanline slicing, chromatic aura, and pulse glow).

@export var is_ghost: bool = false
@export var base_body_color: Color = Color(0.2, 0.5, 0.9)
@export var visor_color: Color = Color(0.3, 0.9, 1.0)

var _pulse: float = 0.0
var _glitch_timer: float = 0.0

func _process(delta: float) -> void:
	if is_ghost:
		_pulse += delta * 4.8
		_glitch_timer += delta * 12.0
		queue_redraw()

func _draw() -> void:
	# Subtle ground contact shadow (oriented to floor regardless of visor facing)
	draw_circle(Vector2(0, 4).rotated(-rotation), 14.0, Color(0, 0, 0, 0.35))
	
	if is_ghost:
		_draw_holographic_aura()
		
	var body_col := base_body_color
	if is_ghost:
		body_col.a = base_body_color.a * (0.8 + 0.2 * sin(_pulse))
		
	# Outer suit body
	draw_circle(Vector2.ZERO, 15.0, body_col)
	draw_arc(Vector2.ZERO, 15.0, 0, TAU, 32, Color(0.1, 0.15, 0.25, 0.9 if not is_ghost else 0.5), 2.0)
	
	# Holographic interior scanlines
	if is_ghost:
		var scan_color := Color(visor_color.r, visor_color.g, visor_color.b, 0.28)
		for sy in [-10.0, -5.0, 0.0, 5.0, 10.0]:
			var half_chord := sqrt(maxf(0.0, 14.0 * 14.0 - sy * sy))
			draw_line(Vector2(-half_chord, sy), Vector2(half_chord, sy), scan_color, 1.0)
			
	# Backpack / oxygen tank
	var pack_col := Color(0.15, 0.2, 0.3, 0.9 if not is_ghost else 0.6)
	draw_rect(Rect2(-8, 8, 16, 6), pack_col, true)
	
	# Helmet visor facing front (towards local negative Y)
	var visor_col := visor_color
	if is_ghost:
		visor_col.a = 0.85 + 0.15 * sin(_pulse * 1.5)
	draw_rect(Rect2(-7, -11, 14, 7), visor_col, true)
	draw_rect(Rect2(-7, -11, 14, 7), Color(1, 1, 1, 0.85), false, 1.0)
	
	# Visor glare
	draw_line(Vector2(-5, -9), Vector2(1, -9), Color(1, 1, 1, 0.95), 1.5)

func _draw_holographic_aura() -> void:
	# Outer harmonic interference rings (Triple-I temporal aesthetics)
	var ring1_r := 18.0 + 3.0 * sin(_pulse)
	var ring2_r := 23.0 + 4.0 * sin(_pulse * 0.7 + 1.2)
	
	var ring1_col := Color(visor_color.r, visor_color.g, visor_color.b, 0.35 + 0.15 * sin(_pulse))
	var ring2_col := Color(visor_color.r, visor_color.g, visor_color.b, 0.18 + 0.10 * cos(_pulse * 0.7))
	
	draw_arc(Vector2.ZERO, ring1_r, 0, TAU, 32, ring1_col, 1.5)
	draw_arc(Vector2.ZERO, ring2_r, 0, TAU, 32, ring2_col, 1.0)
	
	# Holographic projection emitter pips at cardinal axes
	var pip_dist := ring1_r
	var pip_col := Color(1.0, 1.0, 1.0, 0.5)
	draw_circle(Vector2(pip_dist, 0), 1.5, pip_col)
	draw_circle(Vector2(-pip_dist, 0), 1.5, pip_col)
	draw_circle(Vector2(0, pip_dist), 1.5, pip_col)
	draw_circle(Vector2(0, -pip_dist), 1.5, pip_col)
	
	# Micro temporal glitch line occasionally appearing
	if fmod(_glitch_timer, 6.0) > 5.5:
		var glitch_y := sin(_glitch_timer) * 12.0
		draw_line(Vector2(-20, glitch_y), Vector2(20, glitch_y), Color(1, 1, 1, 0.6), 1.2)
