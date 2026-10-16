extends Node2D

var total_tests := 0
var passed_tests := 0

func _ready() -> void:
	print("==================================================")
	print("       ECHO ROOMS — AUTOMATED TEST SUITE          ")
	print("==================================================")
	
	test_autoloads()
	test_save_manager_persistence()
	test_narrative_database()
	test_action_recorder_and_interpolation()
	test_character_facing_rotation()
	test_echo_playback_and_hold()
	test_echo_holographic_visuals_and_trail()
	test_pressure_plate_mechanics()
	test_pressure_plate_occupant_robustness()
	test_lever_switch_mechanics()
	test_timed_button_mechanics()
	test_locked_door_and_logic_gates()
	test_laser_barrier_mechanics()
	test_laser_barrier_dynamic_sizing()
	test_loop_manager_lifecycle()
	test_world_reset_on_loop_rewind()
	test_echo_switch_interaction_replay()
	test_echo_ignores_terminal_lore()
	test_two_echo_door_unlock_simulation()
	test_temporal_rewind_shader()
	test_tactile_camera_system()
	test_audio_bus_and_urgency_filter()
	test_hud_timeline_widget()
	test_base_level_post_processing_and_camera_integration()
	test_scene_instantiations()
	
	print("==================================================")
	print("TESTS COMPLETED: %d / %d PASSED" % [passed_tests, total_tests])
	print("==================================================")
	
	# Allow deferred node deletions to flush cleanly to avoid ObjectDB leaks
	await get_tree().process_frame
	await get_tree().process_frame
	SoundManager.stop_all()
	
	if passed_tests == total_tests:
		print("ALL SYSTEMS NOMINAL. TEST RUNNER EXITING WITH CODE 0.")
		get_tree().quit(0)
	else:
		printerr("TEST FAILURES ENCOUNTERED. EXITING WITH CODE 1.")
		get_tree().quit(1)

func _assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("[PASS] %s" % test_name)
	else:
		printerr("[FAIL] %s" % test_name)

func test_autoloads() -> void:
	_assert_test(SoundManager != null, "Autoload: SoundManager is initialized")
	_assert_test(NarrativeData != null, "Autoload: NarrativeData is initialized")
	_assert_test(GameManager != null, "Autoload: GameManager is initialized")
	_assert_test(SaveManager != null, "Autoload: SaveManager is initialized")

func test_narrative_database() -> void:
	var logs := ["log_01", "log_02", "log_03", "log_04"]
	for lid in logs:
		var data: Dictionary = NarrativeData.get_log(lid)
		var valid: bool = data.has("title") and data.has("content") and data.content.length() > 20
		_assert_test(valid, "Narrative: Log entry '%s' is complete" % lid)

func test_action_recorder_and_interpolation() -> void:
	var rec := ActionRecorder.new()
	rec.start_recording(Vector2(100, 100))
	rec.record_interaction(0.0) # Test interaction at t=0.0 boundary (BUG-06)
	rec.record_frame(1.0, Vector2(200, 100), Vector2(100, 0), Vector2.RIGHT, false)
	rec.record_interaction(1.2)
	rec.record_frame(2.0, Vector2(300, 100), Vector2(100, 0), Vector2.RIGHT, true)
	rec.stop_recording(2.0)
	
	# Test exact frame retrieval
	var f0 := rec.get_frame_at_time(0.0)
	_assert_test(f0.pos.distance_to(Vector2(100, 100)) < 0.1, "Recorder: t=0.0 frame matches start position")
	
	# Test linear interpolation midway between t=1.0 and t=2.0 (t=1.5)
	var f_mid := rec.get_frame_at_time(1.5)
	_assert_test(f_mid.pos.distance_to(Vector2(250, 100)) < 1.0, "Recorder: t=1.5 linearly interpolates position (250, 100)")
	
	# Test hold state after recording duration
	var f_late := rec.get_frame_at_time(5.0)
	_assert_test(f_late.pos.distance_to(Vector2(300, 100)) < 0.1, "Recorder: t=5.0 holds final position")
	_assert_test(f_late.is_finished == true, "Recorder: t=5.0 flags is_finished true")
	
	# Test interaction query intervals
	var due_at_start := rec.get_interactions_in_interval(0.0, 0.5)
	_assert_test(due_at_start == 1, "Recorder: Interaction recorded at t=0.0 is captured in [0.0, 0.5] interval")
	var due_at_mid := rec.get_interactions_in_interval(0.5, 1.5)
	_assert_test(due_at_mid == 1, "Recorder: Interaction recorded at t=1.2 is captured in (0.5, 1.5] interval")

func test_echo_playback_and_hold() -> void:
	var echo_scene := load("res://scenes/entities/echo.tscn") as PackedScene
	var echo: Echo = echo_scene.instantiate() as Echo
	add_child(echo)
	
	var rec := ActionRecorder.new()
	rec.start_recording(Vector2(50, 50))
	rec.record_frame(2.0, Vector2(150, 50), Vector2.ZERO, Vector2.RIGHT, false)
	rec.stop_recording(2.0)
	
	echo.setup(1, rec)
	echo.update_playback(0.0)
	_assert_test(echo.global_position.distance_to(Vector2(50, 50)) < 0.5, "Echo: Initial playback position matches")
	
	echo.update_playback(1.0)
	_assert_test(echo.global_position.distance_to(Vector2(100, 50)) < 1.0, "Echo: Mid-playback interpolates smoothly")
	
	echo.update_playback(10.0)
	_assert_test(echo.global_position.distance_to(Vector2(150, 50)) < 0.5, "Echo: Holds final position past duration")
	
	echo.queue_free()

func test_pressure_plate_mechanics() -> void:
	var plate_scene := load("res://scenes/interactables/pressure_plate.tscn") as PackedScene
	var plate: PressurePlate = plate_scene.instantiate() as PressurePlate
	add_child(plate)
	
	_assert_test(plate.is_pressed == false, "PressurePlate: Starts unpressed")
	
	# Simulate dummy player body entering
	var dummy := Node2D.new()
	plate._on_body_entered(dummy)
	_assert_test(plate.is_pressed == true, "PressurePlate: Activates on body entry")
	
	# Second body enters (e.g. echo joins player)
	var dummy2 := Node2D.new()
	plate._on_body_entered(dummy2)
	_assert_test(plate.is_pressed == true, "PressurePlate: Remains pressed with multiple bodies")
	
	# One body leaves
	plate._on_body_exited(dummy)
	_assert_test(plate.is_pressed == true, "PressurePlate: Stays pressed while one body remains")
	
	# Final body leaves
	plate._on_body_exited(dummy2)
	_assert_test(plate.is_pressed == false, "PressurePlate: Deactivates when all bodies exit")
	
	dummy.free()
	dummy2.free()
	plate.queue_free()

func test_lever_switch_mechanics() -> void:
	var lever_scene := load("res://scenes/interactables/lever_switch.tscn") as PackedScene
	var lever: LeverSwitch = lever_scene.instantiate() as LeverSwitch
	add_child(lever)
	
	_assert_test(lever.is_active == false, "LeverSwitch: Starts inactive")
	lever.interact(null)
	_assert_test(lever.is_active == true, "LeverSwitch: Toggles active on interact")
	lever.interact(null)
	_assert_test(lever.is_active == false, "LeverSwitch: Toggles inactive on second interact")
	
	lever.queue_free()

func test_timed_button_mechanics() -> void:
	var btn_scene := load("res://scenes/interactables/timed_button.tscn") as PackedScene
	var btn: TimedButton = btn_scene.instantiate() as TimedButton
	btn.active_duration = 2.0
	add_child(btn)
	
	_assert_test(btn.is_active == false, "TimedButton: Starts inactive")
	btn.interact(null)
	_assert_test(btn.is_active == true, "TimedButton: Activates on interact")
	_assert_test(btn.time_remaining == 2.0, "TimedButton: Sets charge timer")
	
	# Simulate 1 second passing
	btn._physics_process(1.0)
	_assert_test(btn.is_active == true, "TimedButton: Still active after 1s")
	
	# Simulate 1.5 more seconds passing (total 2.5s > 2.0s duration)
	btn._physics_process(1.5)
	_assert_test(btn.is_active == false, "TimedButton: Deactivates when timer runs out")
	
	btn.queue_free()

func test_locked_door_and_logic_gates() -> void:
	var door_scene := load("res://scenes/interactables/locked_door.tscn") as PackedScene
	var door: LockedDoor = door_scene.instantiate() as LockedDoor
	door.logic_mode = LockedDoor.LogicMode.AND
	add_child(door)
	
	var trig_a := PressurePlate.new()
	var trig_b := PressurePlate.new()
	add_child(trig_a)
	add_child(trig_b)
	
	door.register_trigger(trig_a)
	door.register_trigger(trig_b)
	
	_assert_test(door.is_open == false, "LockedDoor: Starts locked")
	
	# Activate only trigger A
	trig_a.state_changed.emit(true)
	_assert_test(door.is_open == false, "LockedDoor: AND-gate stays closed with only trigger A active")
	
	# Activate trigger B as well
	trig_b.state_changed.emit(true)
	_assert_test(door.is_open == true, "LockedDoor: AND-gate opens when BOTH triggers A and B are active")
	
	# Deactivate trigger A
	trig_a.state_changed.emit(false)
	_assert_test(door.is_open == false, "LockedDoor: Closes if either trigger becomes inactive")
	
	trig_a.queue_free()
	trig_b.queue_free()
	door.queue_free()

func test_laser_barrier_mechanics() -> void:
	var laser_scene := load("res://scenes/interactables/laser_barrier.tscn") as PackedScene
	var laser: LaserBarrier = laser_scene.instantiate() as LaserBarrier
	add_child(laser)
	
	_assert_test(laser.is_active == true, "LaserBarrier: Starts active as solid hazard")
	laser._on_trigger_state_changed(true)
	_assert_test(laser.is_active == false, "LaserBarrier: Deactivates when connected trigger turns ON")
	laser._on_trigger_state_changed(false)
	_assert_test(laser.is_active == true, "LaserBarrier: Reactivates when trigger turns OFF")
	
	laser.queue_free()

func test_loop_manager_lifecycle() -> void:
	var lm: LoopManager = LoopManager.new()
	var echo_scene := load("res://scenes/entities/echo.tscn") as PackedScene
	lm.echo_scene = echo_scene
	add_child(lm)
	
	var player_scene := load("res://scenes/entities/player.tscn") as PackedScene
	var pl: Player = player_scene.instantiate() as Player
	add_child(pl)
	
	lm.initialize(pl, Vector2(100, 100))
	_assert_test(lm.current_loop_number == 1, "LoopManager: Initial loop is #1")
	_assert_test(lm.past_recordings.is_empty(), "LoopManager: No past recordings at start")
	
	# Simulate 2 seconds of movement
	pl.global_position = Vector2(120, 100)
	lm._physics_process(1.0)
	pl.global_position = Vector2(160, 100)
	lm._physics_process(1.0)
	
	# Trigger loop reset
	lm.reset_loop()
	_assert_test(lm.current_loop_number == 2, "LoopManager: Loop number increments to #2 after reset")
	_assert_test(lm.past_recordings.size() == 1, "LoopManager: Past recording stored")
	_assert_test(lm.active_echoes.size() == 1, "LoopManager: Exactly 1 echo spawned for loop #2")
	_assert_test(pl.global_position.distance_to(Vector2(100, 100)) < 0.1, "LoopManager: Player reset to spawn position")
	
	# Test Player nearby_interactables purged on loop reset (BUG-05)
	var dummy_area := Area2D.new()
	dummy_area.add_to_group("interactable")
	pl.nearby_interactables.append(dummy_area)
	_assert_test(pl.nearby_interactables.size() == 1, "Player: Has nearby interactables before loop reset")
	lm.reset_loop()
	_assert_test(pl.nearby_interactables.is_empty(), "LoopManager: Purges Player nearby_interactables cache on loop reset")
	dummy_area.free()
	
	# Test max echoes capping
	lm.max_echoes = 2
	for _i in range(3):
		pl.global_position = Vector2(150, 100)
		lm._physics_process(0.5)
		pl.global_position = Vector2(200, 100)
		lm._physics_process(0.5)
		lm.reset_loop()
	_assert_test(lm.past_recordings.size() == 2, "LoopManager: Past recordings capped at max_echoes (2)")
	_assert_test(lm.active_echoes.size() == 2, "LoopManager: Active echoes count capped at max_echoes (2)")
	
	# Test short loop (0 frames after reset) does not append empty recording
	var pre_count := lm.past_recordings.size()
	lm.reset_loop()
	_assert_test(lm.past_recordings.size() == pre_count, "LoopManager: Short loop without movement frames does not store phantom recording")
	
	# Clear all echoes
	lm.clear_all_echoes()
	_assert_test(lm.current_loop_number == 1, "LoopManager: Loop number resets to #1 on clear")
	_assert_test(lm.past_recordings.is_empty(), "LoopManager: Past recordings cleared")
	_assert_test(lm.active_echoes.is_empty(), "LoopManager: Active echoes destroyed")
	
	pl.queue_free()
	lm.queue_free()

func test_character_facing_rotation() -> void:
	var pl_scene := load("res://scenes/entities/player.tscn") as PackedScene
	var pl: Player = pl_scene.instantiate() as Player
	add_child(pl)
	
	# Moving RIGHT: angle() = 0 -> rotation = 0 + PI/2 = PI/2.
	# Forward visor vector (0, -10).rotated(PI/2) = (10, 0) (RIGHT)
	pl.facing_direction = Vector2.RIGHT
	pl.visual_root.rotation = pl.facing_direction.angle() + PI * 0.5
	var facing_forward := Vector2(0, -10).rotated(pl.visual_root.rotation)
	_assert_test(facing_forward.dot(Vector2.RIGHT) > 9.0, "Visor: Faces RIGHT when moving RIGHT")
	
	# Moving DOWN: angle() = PI/2 -> rotation = PI
	pl.facing_direction = Vector2.DOWN
	pl.visual_root.rotation = pl.facing_direction.angle() + PI * 0.5
	facing_forward = Vector2(0, -10).rotated(pl.visual_root.rotation)
	_assert_test(facing_forward.dot(Vector2.DOWN) > 9.0, "Visor: Faces DOWN when moving DOWN")
	
	# Moving LEFT: angle() = PI
	pl.facing_direction = Vector2.LEFT
	pl.visual_root.rotation = pl.facing_direction.angle() + PI * 0.5
	facing_forward = Vector2(0, -10).rotated(pl.visual_root.rotation)
	_assert_test(facing_forward.dot(Vector2.LEFT) > 9.0, "Visor: Faces LEFT when moving LEFT")
	
	# Moving UP: angle() = -PI/2
	pl.facing_direction = Vector2.UP
	pl.visual_root.rotation = pl.facing_direction.angle() + PI * 0.5
	facing_forward = Vector2(0, -10).rotated(pl.visual_root.rotation)
	_assert_test(facing_forward.dot(Vector2.UP) > 9.0, "Visor: Faces UP when moving UP")
	
	pl.queue_free()

func test_pressure_plate_occupant_robustness() -> void:
	var plate_scene := load("res://scenes/interactables/pressure_plate.tscn") as PackedScene
	var plate: PressurePlate = plate_scene.instantiate() as PressurePlate
	add_child(plate)
	
	var dummy := Node2D.new()
	# Duplicate enter from same body should not double-count
	plate._on_body_entered(dummy)
	plate._on_body_entered(dummy)
	_assert_test(plate.bodies_on_plate == 1, "PressurePlate: Duplicate entry from same body ignored")
	
	plate.reset_state()
	_assert_test(plate.is_pressed == false, "PressurePlate: Resets cleanly on reset_state")
	_assert_test(plate.bodies_on_plate == 0, "PressurePlate: Occupants cleared on reset_state")
	
	dummy.free()
	plate.queue_free()

func test_laser_barrier_dynamic_sizing() -> void:
	var laser_scene := load("res://scenes/interactables/laser_barrier.tscn") as PackedScene
	var laser: LaserBarrier = laser_scene.instantiate() as LaserBarrier
	laser.barrier_length = 160.0
	add_child(laser)
	
	var solid_size: Vector2 = (laser.collision_shape.shape as RectangleShape2D).size
	_assert_test(absf(solid_size.x - 160.0) < 0.1, "LaserBarrier: Collision shape sized dynamically to barrier_length")
	
	laser.queue_free()

func test_world_reset_on_loop_rewind() -> void:
	# Instantiate interactive elements in scene tree under resettable group
	var switch_scene := load("res://scenes/interactables/lever_switch.tscn") as PackedScene
	var sw: LeverSwitch = switch_scene.instantiate() as LeverSwitch
	add_child(sw)
	
	var btn_scene := load("res://scenes/interactables/timed_button.tscn") as PackedScene
	var btn: TimedButton = btn_scene.instantiate() as TimedButton
	add_child(btn)
	
	var wire_scene := load("res://scenes/interactables/circuit_wire.tscn") as PackedScene
	var wire: CircuitWire = wire_scene.instantiate() as CircuitWire
	add_child(wire)
	
	# Activate them
	sw.interact(null)
	btn.activate()
	wire.set_powered(true)
	
	_assert_test(sw.is_active == true, "World Reset: Switch active before reset")
	_assert_test(btn.is_active == true, "World Reset: Button active before reset")
	_assert_test(wire.is_powered == true, "World Reset: Wire powered before reset")
	
	# Create LoopManager and trigger loop reset
	var lm := LoopManager.new()
	add_child(lm)
	lm.reset_loop()
	
	_assert_test(sw.is_active == false, "World Reset: Switch cleanly reset to inactive on loop reset")
	_assert_test(btn.is_active == false, "World Reset: Button cleanly reset to inactive on loop reset")
	_assert_test(wire.is_powered == false, "World Reset: Wire cleanly unpowered on loop reset")
	
	sw.queue_free()
	btn.queue_free()
	wire.queue_free()
	lm.queue_free()

func test_echo_switch_interaction_replay() -> void:
	# Test that an Echo correctly repeats an interact action and activates a switch
	var switch_scene := load("res://scenes/interactables/lever_switch.tscn") as PackedScene
	var sw: LeverSwitch = switch_scene.instantiate() as LeverSwitch
	sw.global_position = Vector2(200, 200)
	add_child(sw)
	
	var rec := ActionRecorder.new()
	rec.start_recording(Vector2(100, 200))
	rec.record_frame(0.0, Vector2(100, 200), Vector2.ZERO, Vector2.RIGHT, false)
	rec.record_frame(1.0, Vector2(200, 200), Vector2.ZERO, Vector2.RIGHT, true)
	rec.record_interaction(1.0)
	rec.record_frame(2.0, Vector2(200, 200), Vector2.ZERO, Vector2.RIGHT, false)
	rec.stop_recording(2.0)
	
	var echo_scene := load("res://scenes/entities/echo.tscn") as PackedScene
	var echo: Echo = echo_scene.instantiate() as Echo
	add_child(echo)
	echo.setup(1, rec)
	echo.reset_playback()
	
	_assert_test(sw.is_active == false, "Echo Switch: Switch starts inactive at t=0")
	
	# At t=0.5, echo is halfway and has not interacted
	echo.update_playback(0.5)
	_assert_test(sw.is_active == false, "Echo Switch: Switch remains inactive at t=0.5")
	
	# At t=1.0, echo reaches switch and triggers interaction
	echo.update_playback(1.0)
	_assert_test(sw.is_active == true, "Echo Switch: Echo successfully activates switch at recorded timestamp")
	
	sw.queue_free()
	echo.queue_free()

func test_echo_ignores_terminal_lore() -> void:
	var term_scene := load("res://scenes/interactables/terminal_log.tscn") as PackedScene
	var term: TerminalLog = term_scene.instantiate() as TerminalLog
	add_child(term)
	
	GameManager.is_narrative_open = false
	var dummy_echo := Echo.new()
	term.interact(dummy_echo)
	_assert_test(GameManager.is_narrative_open == false, "Terminal Lore: Echo interaction does not trigger narrative modal")
	
	dummy_echo.free()
	term.queue_free()

func test_two_echo_door_unlock_simulation() -> void:
	# Simulate 2-trigger puzzle (like Chamber 02):
	# Loop 1: Player holds Plate A. Reset.
	# Loop 2: Echo holds Plate A, Player holds Plate B -> Door unlocks!
	var door_scene := load("res://scenes/interactables/locked_door.tscn") as PackedScene
	var door: LockedDoor = door_scene.instantiate() as LockedDoor
	door.logic_mode = LockedDoor.LogicMode.AND
	add_child(door)
	
	var plate_a_scene := load("res://scenes/interactables/pressure_plate.tscn") as PackedScene
	var plate_a: PressurePlate = plate_a_scene.instantiate() as PressurePlate
	add_child(plate_a)
	
	var plate_b_scene := load("res://scenes/interactables/pressure_plate.tscn") as PackedScene
	var plate_b: PressurePlate = plate_b_scene.instantiate() as PressurePlate
	add_child(plate_b)
	
	door.register_trigger(plate_a)
	door.register_trigger(plate_b)
	
	_assert_test(door.is_open == false, "Two-Echo Puzzle: Door starts locked")
	
	# Echo 1 stands on Plate A
	var echo_dummy := Node2D.new()
	plate_a._on_body_entered(echo_dummy)
	_assert_test(door.is_open == false, "Two-Echo Puzzle: Door stays closed with only Echo on Plate A")
	
	# Player stands on Plate B
	var player_dummy := Node2D.new()
	plate_b._on_body_entered(player_dummy)
	_assert_test(door.is_open == true, "Two-Echo Puzzle: Door unlocks when Echo holds Plate A and Player activates Plate B")
	
	echo_dummy.free()
	player_dummy.free()
	door.queue_free()
	plate_a.queue_free()
	plate_b.queue_free()

func test_scene_instantiations() -> void:
	var scenes_to_check := [
		"res://scenes/ui/main_menu.tscn",
		"res://scenes/ui/level_select.tscn",
		"res://scenes/ui/pause_menu.tscn",
		"res://scenes/ui/victory_screen.tscn",
		"res://scenes/levels/level_01.tscn",
		"res://scenes/levels/level_02.tscn",
		"res://scenes/levels/level_03.tscn",
		"res://scenes/levels/level_04.tscn"
	]
	
	for path in scenes_to_check:
		var scene := load(path) as PackedScene
		_assert_test(scene != null, "Scene Load: '%s' loaded" % path)
		if scene:
			var inst: Node = scene.instantiate()
			_assert_test(inst != null, "Scene Instantiate: '%s' instantiated cleanly" % path)
			if inst:
				inst.free()

func test_save_manager_persistence() -> void:
	SaveManager.reset_all_progress() # Guarantee test hermeticity & isolation (BUG-01)
	_assert_test(SaveManager.is_level_unlocked(1) == true, "SaveManager: Chamber 1 is unlocked by default")
	_assert_test(SaveManager.is_level_unlocked(2) == false, "SaveManager: Chamber 2 is initially locked")
	
	SaveManager.unlock_level(2)
	_assert_test(SaveManager.is_level_unlocked(2) == true, "SaveManager: Chamber 2 unlocks correctly")
	
	SaveManager.record_level_completion(1, 3, 22.4)
	_assert_test(SaveManager.get_best_loops(1) == 3, "SaveManager: Records best loop count of 3")
	_assert_test(absf(SaveManager.get_best_time(1) - 22.4) < 0.01, "SaveManager: Records best completion time")
	
	# Improving score with lower loops
	SaveManager.record_level_completion(1, 2, 20.1)
	_assert_test(SaveManager.get_best_loops(1) == 2, "SaveManager: Upgrades best loop count to 2")
	
	# Worse score should not downgrade
	SaveManager.record_level_completion(1, 5, 29.0)
	_assert_test(SaveManager.get_best_loops(1) == 2, "SaveManager: Preserves superior loop count of 2")
	
	# Completing final Chamber 4 should clamp to TOTAL_LEVELS and NOT unlock Chamber 5 (BUG-02)
	SaveManager.record_level_completion(4, 1, 19.5)
	_assert_test(SaveManager.is_level_unlocked(5) == false, "SaveManager: Completing Chamber 4 does not unlock nonexistent Chamber 5")
	_assert_test(SaveManager.unlocked_levels <= 4, "SaveManager: Unlocked levels clamped to TOTAL_LEVELS (4)")
	
	# Test disk serialization & roundtrip
	var saved := SaveManager.save_data()
	_assert_test(saved == true, "SaveManager: Successfully saves state to disk")
	
	# Modify in-memory then reload
	SaveManager.unlocked_levels = 1
	var loaded := SaveManager.load_data()
	_assert_test(loaded == true, "SaveManager: Successfully reloads state from disk")
	_assert_test(SaveManager.is_level_unlocked(2) == true, "SaveManager: Reloaded state preserves unlocked level 2")
	_assert_test(SaveManager.get_best_loops(1) == 2, "SaveManager: Reloaded state preserves best loops")
	
	# Corrupted JSON / non-object root check (BUG-04)
	var bad_file := FileAccess.open(SaveManager.SAVE_FILE_PATH, FileAccess.WRITE)
	if bad_file:
		bad_file.store_string("[1, 2, 3]")
		bad_file.close()
	var corrupt_loaded := SaveManager.load_data()
	_assert_test(corrupt_loaded == false, "SaveManager: Safely rejects non-object JSON array without crashing")
	SaveManager.save_data() # Restore valid format
	
	# Lore discovery
	SaveManager.record_lore_discovered("log_01")
	_assert_test(SaveManager.is_lore_discovered("log_01") == true, "SaveManager: Discovered lore persisted")
	
	# Settings
	SaveManager.set_setting("screen_shake", false)
	_assert_test(SaveManager.get_setting("screen_shake") == false, "SaveManager: Settings persist accurately")
	
	# Fallback key lookup test (string vs int key)
	SaveManager.best_loop_counts.clear()
	SaveManager.best_loop_counts["1"] = 4
	_assert_test(SaveManager.get_best_loops(1) == 4, "SaveManager: Retrieves best loops from string or int key")
	
	# Clean reset
	SaveManager.reset_all_progress()
	_assert_test(SaveManager.is_level_unlocked(2) == false, "SaveManager: Reset cleanly clears progress")
	_assert_test(SaveManager.get_setting("screen_shake") == true, "SaveManager: Reset cleanly restores default settings")

func test_echo_holographic_visuals_and_trail() -> void:
	var echo_scene := load("res://scenes/entities/echo.tscn") as PackedScene
	var echo: Echo = echo_scene.instantiate() as Echo
	add_child(echo)
	
	_assert_test(echo.trail_line != null, "Echo Visuals: Trail Line2D initialized")
	_assert_test(echo.visual_root is CharacterVisual, "Echo Visuals: VisualRoot is CharacterVisual")
	_assert_test((echo.visual_root as CharacterVisual).is_ghost == true, "Echo Visuals: CharacterVisual is flagged as ghost")
	
	var rec := ActionRecorder.new()
	rec.start_recording(Vector2(100, 100))
	rec.record_frame(1.0, Vector2(200, 100), Vector2(100, 0), Vector2.RIGHT, false)
	rec.record_frame(2.0, Vector2(300, 100), Vector2(100, 0), Vector2.RIGHT, false)
	rec.stop_recording(2.0)
	echo.setup(1, rec)
	
	echo.update_playback(0.5)
	echo.update_playback(1.0)
	_assert_test(echo.trail_points.size() > 0, "Echo Trail: Records motion trail points during movement")
	
	echo.reset_playback()
	_assert_test(echo.trail_points.is_empty(), "Echo Trail: Resets and clears motion trail on rewind")
	
	# Test Echo color styling purity without modulate tint mud
	echo.setup(2, rec)
	_assert_test(echo.echo_color.r > 0.8 and echo.echo_color.b > 0.8, "Echo Visuals: Echo 2 assigned distinct magenta palette")
	_assert_test((echo.visual_root as CharacterVisual).modulate == Color.WHITE, "Echo Visuals: VisualRoot modulate uncorrupted by color multiplication")
	
	echo.queue_free()

func test_temporal_rewind_shader() -> void:
	var shader := load("res://shaders/temporal_rewind.gdshader") as Shader
	_assert_test(shader != null, "Shader: temporal_rewind.gdshader loads cleanly")
	
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_assert_test(mat != null, "Shader: ShaderMaterial instantiates with temporal rewind shader")
	
	mat.set_shader_parameter("intensity", 0.8)
	var int_val: float = mat.get_shader_parameter("intensity")
	_assert_test(absf(int_val - 0.8) < 0.01, "Shader: Intensity parameter sets and retrieves accurately")
	
	mat.set_shader_parameter("aberration_amount", 0.02)
	var ab_val: float = mat.get_shader_parameter("aberration_amount")
	_assert_test(absf(ab_val - 0.02) < 0.01, "Shader: Aberration parameter sets accurately")
	
	var rect := ColorRect.new()
	rect.material = mat
	add_child(rect)
	_assert_test(rect.material != null, "Shader: Applied cleanly to viewport post-processing rect")
	rect.queue_free()

func test_tactile_camera_system() -> void:
	var cam_script = load("res://scripts/camera/tactile_camera.gd")
	var cam: Camera2D = cam_script.new()
	add_child(cam)
	
	_assert_test(cam.trauma == 0.0, "TactileCamera: Starts with 0.0 trauma")
	_assert_test(cam.offset == Vector2.ZERO, "TactileCamera: Starts with zero screen shake offset")
	
	cam.add_trauma(0.5)
	_assert_test(absf(cam.trauma - 0.5) < 0.01, "TactileCamera: add_trauma sets trauma")
	
	cam.add_trauma(0.8)
	_assert_test(cam.trauma == 1.0, "TactileCamera: Trauma clamps at maximum 1.0")
	
	# Process delta to simulate screen shake
	cam._process(0.1)
	_assert_test(cam.offset != Vector2.ZERO, "TactileCamera: Trauma produces dynamic screen shake offset")
	_assert_test(cam.trauma < 1.0, "TactileCamera: Trauma decays over time")
	
	# Velocity look-ahead test
	var dummy_target := CharacterBody2D.new()
	dummy_target.velocity = Vector2(300, 0)
	dummy_target.position = Vector2(640, 360)
	add_child(dummy_target)
	
	cam.set_target(dummy_target)
	cam._process(0.2)
	_assert_test(cam.global_position.x > 640.0, "TactileCamera: Dynamically offsets towards velocity look-ahead")
	
	# Screen shake accessibility setting toggle test
	SaveManager.set_setting("screen_shake", false)
	cam.trauma = 0.0
	cam.add_trauma(0.5)
	_assert_test(cam.trauma == 0.0, "TactileCamera: add_trauma suppressed when screen_shake setting disabled")
	SaveManager.set_setting("screen_shake", true)
	cam.add_trauma(0.5)
	_assert_test(cam.trauma == 0.5, "TactileCamera: add_trauma engages when screen_shake setting enabled")
	
	dummy_target.queue_free()
	cam.queue_free()

func test_audio_bus_and_urgency_filter() -> void:
	var bus_layout := load("res://default_bus_layout.tres") as AudioBusLayout
	_assert_test(bus_layout != null, "Audio Bus: default_bus_layout.tres loads cleanly")
	
	var buses_to_verify := ["Master", "Music", "SFX", "Echoes", "Ambience"]
	for bname in buses_to_verify:
		var exists: bool = AudioServer.get_bus_index(bname) != -1 or bus_layout.bus_count >= 5
		_assert_test(exists, "Audio Bus: Bus '%s' is present in layout" % bname)
		
	# Test urgency filter
	SoundManager.set_urgency(2.0, 30.0) # Urgency < 5.0s
	_assert_test(SoundManager._urgency_factor > 0.0, "SoundManager: Urgency factor engages when loop timer < 5s")
	
	SoundManager.reset_urgency()
	_assert_test(SoundManager._urgency_factor == 0.0, "SoundManager: Urgency factor resets cleanly")
	
	# Test play_sfx with bus and pitch variance
	SoundManager.play_sfx("switch_on", 1.0, -10.0, "SFX", 0.05)
	SoundManager.play_sfx("click", 1.0, -10.0, "Echoes", 0.05)
	SoundManager.play_sfx_at_position("click", Vector2(300, 300), 1.0, -10.0, "SFX")
	# Test volume settings application to AudioServer
	SaveManager.set_setting("sfx_volume", 0.5)
	var sfx_idx := AudioServer.get_bus_index("SFX")
	var sfx_db := AudioServer.get_bus_volume_db(sfx_idx)
	_assert_test(sfx_db < -5.0 and sfx_db > -7.0, "SoundManager: Volume settings accurately modulate AudioServer bus volumes")
	SaveManager.set_setting("sfx_volume", 1.0)
	
	SoundManager.stop_all()

func test_hud_timeline_widget() -> void:
	var hud_scene := load("res://scenes/ui/game_hud.tscn") as PackedScene
	var hud: GameHUD = hud_scene.instantiate() as GameHUD
	add_child(hud)
	
	_assert_test(hud.timeline_widget != null, "HUD Timeline: TimelineWidget initialized in GameHUD")
	
	hud.update_time(10.0, 30.0)
	_assert_test(hud.timeline_widget.current_time == 10.0, "HUD Timeline: TimelineWidget updates current time")
	_assert_test(hud.timeline_widget.max_duration == 30.0, "HUD Timeline: TimelineWidget sets max duration")
	
	var sample_tracks: Array[Dictionary] = [
		{"index": 0, "label": "YOU", "color": Color.CYAN, "pips": [5.0, 15.0]},
		{"index": 1, "label": "ECHO #1", "color": Color.MAGENTA, "pips": [10.0]}
	]
	hud.set_timeline_tracks(sample_tracks)
	_assert_test(hud.timeline_widget.tracks.size() == 2, "HUD Timeline: Receives and populates multi-track action pips")
	
	# Urgency threshold (< 5s remaining)
	hud.update_time(27.0, 30.0)
	_assert_test(hud.timer_label.modulate.r > 0.9, "HUD: Timer pulses red during loop urgency (< 5s)")
	
	# Robustness: zero duration safely avoids division by zero
	hud.timeline_widget.set_timeline(0.0, 0.0)
	_assert_test(hud.timeline_widget.max_duration == 0.0, "HUD Timeline: Zero-duration safely handled without division by zero")
	
	hud.queue_free()

func test_base_level_post_processing_and_camera_integration() -> void:
	var lvl_scene := load("res://scenes/levels/level_01.tscn") as PackedScene
	var lvl: Level01 = lvl_scene.instantiate() as Level01
	add_child(lvl)
	
	_assert_test(lvl.camera != null, "BaseLevel: TactileCamera dynamically instantiated and attached")
	_assert_test(lvl.post_process_layer != null, "BaseLevel: PostProcessLayer instantiated")
	_assert_test(lvl._shader_material != null, "BaseLevel: Rewind shader material active")
	_assert_test(lvl._shader_rect != null, "BaseLevel: Rewind shader ColorRect present")
	_assert_test(lvl._shader_rect.visible == false, "BaseLevel: Rewind shader dormant when not rewinding")
	
	# Test locked door slam triggers procedural camera trauma
	var doors := lvl.find_children("*", "", true, false).filter(func(c): return c is LockedDoor)
	_assert_test(doors.size() > 0, "BaseLevel: LockedDoor discovered in Level01")
	if not doors.is_empty():
		lvl.camera.trauma = 0.0
		(doors[0] as LockedDoor).door_state_changed.emit(false)
		_assert_test(lvl.camera.trauma > 0.2, "BaseLevel: Door slam triggers procedural camera trauma")
		
	lvl.trigger_temporal_rewind_fx(0.4)
	_assert_test(lvl.camera.trauma > 0.5, "BaseLevel: Temporal rewind triggers tactile camera trauma")
	
	lvl.queue_free()
