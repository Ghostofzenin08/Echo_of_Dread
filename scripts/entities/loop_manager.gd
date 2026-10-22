class_name LoopManager
extends Node2D

signal time_updated(current_time: float, max_duration: float)
signal loop_reset(new_loop_number: int)
signal echoes_cleared
signal echo_count_changed(count: int)
signal timeline_tracks_updated(tracks: Array)
signal rewind_blocked(reason: String)
signal loop_duration_changed(new_duration: float)

@export var level_number: int = 1
@export var loop_duration: float = 30.0
@export var max_echoes: int = 5
@export var echo_scene: PackedScene = null

var current_loop_time: float = 0.0
var current_loop_number: int = 1
var past_recordings: Array[ActionRecorder] = []
var active_echoes: Array[Echo] = []

var current_recorder: ActionRecorder = null
var player: Player = null
var spawn_position: Vector2 = Vector2.ZERO
var is_active: bool = true
var _t_key_pressed: bool = false

var echoes_container: Node2D = null

func _ready() -> void:
	add_to_group("loop_manager")
	if has_node("EchoesContainer"):
		echoes_container = get_node("EchoesContainer") as Node2D
	else:
		echoes_container = Node2D.new()
		echoes_container.name = "EchoesContainer"
		add_child(echoes_container)

func initialize(target_player: Player, initial_spawn: Vector2) -> void:
	player = target_player
	spawn_position = initial_spawn
	if player:
		if player.has_method("reset_state"):
			player.reset_state(spawn_position)
		else:
			player.global_position = spawn_position
		
		if not player.interaction_performed.is_connected(_on_player_interaction):
			player.interaction_performed.connect(_on_player_interaction)
		
	if GameManager:
		if not GameManager.loop_reset_requested.is_connected(_on_manual_reset_requested):
			GameManager.loop_reset_requested.connect(_on_manual_reset_requested)
		if not GameManager.echoes_cleared_requested.is_connected(clear_all_echoes):
			GameManager.echoes_cleared_requested.connect(clear_all_echoes)
	
	current_loop_time = 0.0
	current_loop_number = 1
	past_recordings.clear()
	_clear_echo_nodes()
	
	# Apply early chamber fast loop duration (Chambers 1-5 only)
	if level_number >= 1 and level_number <= 5 and SaveManager and SaveManager.is_fast_early_loops():
		loop_duration = 15.0
	else:
		loop_duration = 30.0
	
	_reset_world_entities()
	
	current_recorder = ActionRecorder.new()
	var start_pos: Vector2 = player.global_position if player else spawn_position
	current_recorder.start_recording(start_pos)
	is_active = true
	time_updated.emit(0.0, loop_duration)
	echo_count_changed.emit(0)
	timeline_tracks_updated.emit(get_all_timeline_tracks())

func _on_player_interaction(_target: Node2D) -> void:
	if current_recorder and current_recorder.is_recording:
		current_recorder.record_interaction(current_loop_time)
		timeline_tracks_updated.emit(get_all_timeline_tracks())

func _reset_world_entities() -> void:
	for node in get_tree().get_nodes_in_group("resettable"):
		if is_instance_valid(node) and node.has_method("reset_state"):
			node.reset_state()

func is_manual_rewind_unlocked() -> bool:
	if level_number <= 10:
		return false
	if SaveManager and not SaveManager.is_rewind_unlocked():
		return false
	return true

func set_loop_duration(new_duration: float) -> void:
	if level_number >= 1 and level_number <= 5:
		loop_duration = clampf(new_duration, 15.0, 30.0)
	else:
		loop_duration = 30.0
	time_updated.emit(current_loop_time, loop_duration)
	loop_duration_changed.emit(loop_duration)
	if current_loop_time >= loop_duration:
		reset_loop()

func toggle_early_loop_duration() -> float:
	if level_number < 1 or level_number > 5:
		return 30.0
	var new_target: float = 15.0 if is_equal_approx(loop_duration, 30.0) else 30.0
	set_loop_duration(new_target)
	if SaveManager:
		SaveManager.set_fast_early_loops(is_equal_approx(new_target, 15.0))
	return loop_duration

func _on_manual_reset_requested() -> void:
	if is_manual_rewind_unlocked():
		reset_loop()
	else:
		SoundManager.play_sfx("click")
		rewind_blocked.emit("MANUAL REWIND LOCKED — Unlocks after Chamber 10")

func _physics_process(delta: float) -> void:
	if not is_active or GameManager.is_paused or GameManager.is_narrative_open:
		return
		
	# Check manual hotkeys
	if Input.is_action_just_pressed("reset_loop"):
		_on_manual_reset_requested()
		return
		
	if Input.is_action_just_pressed("clear_echoes"):
		clear_all_echoes()
		return
		
	# Hotkey [T] for early chamber fast loop duration (Chambers 1-5 only)
	if level_number >= 1 and level_number <= 5:
		if Input.is_key_pressed(KEY_T) and not _t_key_pressed:
			_t_key_pressed = true
			SoundManager.play_sfx("click")
			toggle_early_loop_duration()
		elif not Input.is_key_pressed(KEY_T):
			_t_key_pressed = false
		
	current_loop_time += delta
	time_updated.emit(current_loop_time, loop_duration)
	
	# Record current player frame
	if player and current_recorder and current_recorder.is_recording:
		current_recorder.record_frame(
			current_loop_time,
			player.global_position,
			player.velocity,
			player.facing_direction,
			player.is_interacting
		)
		
	# Update playback on all active echoes
	for echo in active_echoes:
		if is_instance_valid(echo):
			echo.update_playback(current_loop_time)
			
	# Auto-reset when loop duration expires
	if current_loop_time >= loop_duration:
		reset_loop()

func reset_loop() -> void:
	SoundManager.play_sfx("loop_rewind")
	
	# Stop and save current recording if there is valid duration
	if current_recorder:
		current_recorder.stop_recording(current_loop_time)
		if current_recorder.frames.size() > 2:
			past_recordings.append(current_recorder.duplicate_recording())
			if past_recordings.size() > max_echoes:
				past_recordings.pop_front()
				
	current_loop_number += 1
	current_loop_time = 0.0
	
	# Reset player position, velocity, and interaction state
	if player:
		if player.has_method("reset_state"):
			player.reset_state(spawn_position)
		else:
			player.global_position = spawn_position
			player.velocity = Vector2.ZERO
		
	# Reset all puzzle interactables and hazard states
	_reset_world_entities()
	
	# Rebuild and spawn echoes
	_respawn_echoes()
	
	# Start new recording for the new loop
	current_recorder = ActionRecorder.new()
	if player:
		current_recorder.start_recording(player.global_position)
		
	loop_reset.emit(current_loop_number)
	echo_count_changed.emit(active_echoes.size())
	time_updated.emit(0.0, loop_duration)
	timeline_tracks_updated.emit(get_all_timeline_tracks())

func clear_all_echoes() -> void:
	SoundManager.play_sfx("switch_off")
	past_recordings.clear()
	_clear_echo_nodes()
	current_loop_number = 1
	current_loop_time = 0.0
	
	if player:
		if player.has_method("reset_state"):
			player.reset_state(spawn_position)
		else:
			player.global_position = spawn_position
			player.velocity = Vector2.ZERO
		
	# Reset all puzzle interactables and hazard states
	_reset_world_entities()
	
	current_recorder = ActionRecorder.new()
	if player:
		current_recorder.start_recording(player.global_position)
		
	echoes_cleared.emit()
	echo_count_changed.emit(0)
	loop_reset.emit(1)
	time_updated.emit(0.0, loop_duration)
	timeline_tracks_updated.emit(get_all_timeline_tracks())

func get_all_timeline_tracks() -> Array[Dictionary]:
	var tracks: Array[Dictionary] = []
	var player_pips: Array[float] = []
	if current_recorder:
		player_pips = current_recorder.interaction_times.duplicate()
	tracks.append({
		"index": 0,
		"label": "YOU",
		"color": Color(0.2, 0.9, 1.0),
		"pips": player_pips
	})
	
	for i in range(past_recordings.size()):
		var col: Color = Echo.ECHO_COLORS[i % Echo.ECHO_COLORS.size()]
		tracks.append({
			"index": i + 1,
			"label": "ECHO #%d" % (i + 1),
			"color": col,
			"pips": past_recordings[i].interaction_times.duplicate()
		})
	return tracks

func _clear_echo_nodes() -> void:
	for echo in active_echoes:
		if is_instance_valid(echo):
			echo.queue_free()
	active_echoes.clear()

func _respawn_echoes() -> void:
	_clear_echo_nodes()
	
	for i in range(past_recordings.size()):
		var recorder: ActionRecorder = past_recordings[i]
		var echo_instance: Echo = null
		if echo_scene:
			echo_instance = echo_scene.instantiate() as Echo
		else:
			# Fallback procedural instantiation
			echo_instance = Echo.new()
			
		echo_instance.setup(i + 1, recorder)
		echoes_container.add_child(echo_instance)
		echo_instance.reset_playback()
		active_echoes.append(echo_instance)
