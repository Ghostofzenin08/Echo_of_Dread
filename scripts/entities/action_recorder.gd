class_name ActionRecorder
extends RefCounted

# Records player trajectory and input events over the course of a 30-second loop

var frames: Array[Dictionary] = []
var interaction_times: Array[float] = []
var start_position: Vector2 = Vector2.ZERO
var total_duration: float = 0.0
var is_recording: bool = false

func start_recording(initial_pos: Vector2) -> void:
	frames.clear()
	interaction_times.clear()
	start_position = initial_pos
	total_duration = 0.0
	is_recording = true
	record_frame(0.0, initial_pos, Vector2.ZERO, Vector2.DOWN, false)

func record_frame(time_offset: float, pos: Vector2, vel: Vector2, facing: Vector2, is_interacting: bool) -> void:
	if not is_recording:
		return
	total_duration = time_offset
	frames.append({
		"time": time_offset,
		"pos": pos,
		"vel": vel,
		"facing": facing,
		"interact": is_interacting
	})

func record_interaction(time_offset: float) -> void:
	if not is_recording:
		return
	interaction_times.append(time_offset)

func get_interactions_in_interval(start_time: float, end_time: float) -> int:
	var count := 0
	for t in interaction_times:
		var in_window := (t >= start_time and t <= end_time) if start_time <= 0.0 else (t > start_time and t <= end_time)
		if in_window:
			count += 1
	return count

func stop_recording(final_time: float) -> void:
	is_recording = false
	total_duration = final_time

func duplicate_recording() -> ActionRecorder:
	var copy := ActionRecorder.new()
	copy.start_position = self.start_position
	copy.total_duration = self.total_duration
	copy.is_recording = false
	copy.frames = self.frames.duplicate(true)
	copy.interaction_times = self.interaction_times.duplicate()
	return copy

func get_frame_at_time(time_offset: float) -> Dictionary:
	if frames.is_empty():
		return {
			"pos": start_position,
			"vel": Vector2.ZERO,
			"facing": Vector2.DOWN,
			"interact": false,
			"is_finished": true
		}
		
	# If time exceeds recorded duration, stay at the final recorded frame
	if time_offset >= total_duration or time_offset >= frames.back()["time"]:
		var last: Dictionary = frames.back()
		return {
			"pos": last["pos"],
			"vel": Vector2.ZERO,
			"facing": last["facing"],
			"interact": false,
			"is_finished": true
		}
		
	if time_offset <= frames.front()["time"]:
		var first: Dictionary = frames.front()
		return {
			"pos": first["pos"],
			"vel": first["vel"],
			"facing": first["facing"],
			"interact": first["interact"],
			"is_finished": false
		}
		
	# Binary search to find surrounding frames for interpolation
	var low := 0
	var high := frames.size() - 1
	while low <= high:
		var mid := (low + high) / 2
		if frames[mid]["time"] <= time_offset:
			low = mid + 1
		else:
			high = mid - 1
			
	var idx1 := clampi(high, 0, frames.size() - 1)
	var idx2 := clampi(low, 0, frames.size() - 1)
	
	if idx1 == idx2:
		var frame: Dictionary = frames[idx1]
		return {
			"pos": frame["pos"],
			"vel": frame["vel"],
			"facing": frame["facing"],
			"interact": frame["interact"],
			"is_finished": false
		}
		
	var f1: Dictionary = frames[idx1]
	var f2: Dictionary = frames[idx2]
	var span: float = f2["time"] - f1["time"]
	var factor: float = 0.0
	if span > 0.0001:
		factor = clampf((time_offset - f1["time"]) / span, 0.0, 1.0)
		
	var interpolated_pos: Vector2 = f1["pos"].lerp(f2["pos"], factor)
	var interpolated_vel: Vector2 = f1["vel"].lerp(f2["vel"], factor)
	var facing: Vector2 = f2["facing"] if factor >= 0.5 else f1["facing"]
	var interact: bool = false
	if factor < 0.01:
		interact = f1["interact"]
	elif factor > 0.99:
		interact = f2["interact"]
	
	return {
		"pos": interpolated_pos,
		"vel": interpolated_vel,
		"facing": facing,
		"interact": interact,
		"is_finished": false
	}
