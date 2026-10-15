class_name TimelineWidget
extends Control

# TimelineWidget: Multi-track temporal timeline visualizer.
# Renders progress fill, danger-zone urgency pulsing (< 5s), 5-second tick marks,
# playhead indicator, and multi-track visual action pips for player and echoes.

@export var max_duration: float = 30.0
@export var current_time: float = 0.0

var tracks: Array[Dictionary] = []
var _pulse: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(280, 22)
	queue_redraw()

func _process(delta: float) -> void:
	var remaining: float = max_duration - current_time
	if remaining <= 5.0 and remaining > 0.0:
		_pulse += delta * 8.0
		queue_redraw()

func set_timeline(time: float, duration: float) -> void:
	current_time = time
	max_duration = duration
	queue_redraw()

func set_tracks(new_tracks: Array) -> void:
	tracks = new_tracks
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0 or h <= 0:
		return
		
	var safe_duration := maxf(0.001, max_duration)
	var remaining := maxf(0.0, safe_duration - current_time)
	var progress := clampf(current_time / safe_duration, 0.0, 1.0)
	
	# Background track trough
	var bg_rect := Rect2(0, 0, w, h)
	draw_rect(bg_rect, Color(0.06, 0.09, 0.14, 0.95), true)
	draw_rect(bg_rect, Color(0.2, 0.28, 0.4, 0.8), false, 1.0)
	
	# Urgent danger zone (final 5 seconds on the right)
	var danger_start_x := clampf(((safe_duration - 5.0) / safe_duration) * w, 0.0, w)
	var danger_w := w - danger_start_x
	var danger_alpha := 0.15
	if remaining <= 5.0:
		danger_alpha = 0.25 + 0.15 * sin(_pulse)
	draw_rect(Rect2(danger_start_x, 1, danger_w, h - 2), Color(1.0, 0.2, 0.25, danger_alpha), true)
	
	# 5-second interval tick marks
	var num_ticks := int(safe_duration / 5.0)
	for i in range(1, num_ticks):
		var tx := (float(i * 5) / safe_duration) * w
		draw_line(Vector2(tx, 2), Vector2(tx, h - 2), Color(0.25, 0.35, 0.5, 0.5), 1.0)
		
	# Active temporal progress fill
	var fill_w := progress * w
	if fill_w > 0.0:
		var fill_color := Color(0.15, 0.65, 0.9, 0.45)
		if remaining <= 5.0:
			fill_color = Color(1.0, 0.25, 0.25, 0.55 + 0.15 * sin(_pulse))
		elif remaining <= 10.0:
			fill_color = Color(0.9, 0.7, 0.2, 0.45)
		draw_rect(Rect2(0, 2, fill_w, h - 4), fill_color, true)
		
	# Action pips for each track (Player and Echoes)
	var track_count := maxi(1, tracks.size())
	var track_height := (h - 6) / float(track_count)
	var pip_size := clampf(track_height * 0.42, 1.5, 3.5)
	
	for t_idx in range(tracks.size()):
		var track: Dictionary = tracks[t_idx]
		var col: Color = track.get("color", Color.WHITE)
		var pips: Array = track.get("pips", [])
		var pip_y := 3.0 + t_idx * track_height + track_height * 0.5
		
		# Track divider line
		if t_idx > 0:
			draw_line(Vector2(2, 3.0 + t_idx * track_height), Vector2(w - 2, 3.0 + t_idx * track_height), Color(col.r, col.g, col.b, 0.15), 1.0)
			
		for pip_val in pips:
			var pip_time: float = float(pip_val)
			var px := clampf((pip_time / safe_duration) * w, pip_size + 1.0, w - pip_size - 1.0)
			# Draw diamond pip
			var pts := PackedVector2Array([
				Vector2(px, pip_y - pip_size),
				Vector2(px + pip_size, pip_y),
				Vector2(px, pip_y + pip_size),
				Vector2(px - pip_size, pip_y)
			])
			draw_colored_polygon(pts, col)
			# Specular highlight
			draw_circle(Vector2(px, pip_y), maxf(1.0, pip_size * 0.4), Color(1, 1, 1, 0.9))
			
	# Glowing playhead cursor
	var cursor_x := clampf(fill_w, 1.0, w - 1.0)
	var playhead_col := Color(0.4, 0.95, 1.0, 1.0)
	if remaining <= 5.0:
		playhead_col = Color(1.0, 0.3, 0.3, 1.0)
	draw_line(Vector2(cursor_x, 0), Vector2(cursor_x, h), playhead_col, 2.0)
	draw_circle(Vector2(cursor_x, 1), 2.5, Color.WHITE)
	draw_circle(Vector2(cursor_x, h - 1), 2.5, Color.WHITE)
