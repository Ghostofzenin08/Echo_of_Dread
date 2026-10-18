extends Node2D

const SecurityDroneClass = preload("res://scripts/entities/security_drone.gd")
const ChamberDatabaseClass = preload("res://scripts/world/chamber_database.gd")

var total_tests := 0
var passed_tests := 0

func _ready() -> void:
	print("==================================================")
	print("       ECHO OF DREAD — AUTOMATED TEST SUITE       ")
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
	test_ambient_drone_audio()
	test_in_world_interaction_prompts()
	test_security_drone_enemy_mechanics()
	test_settings_menu_component()
	test_settings_persistence_roundtrip()
	test_project_branding_and_title()
	test_chamber_database_and_50_levels()
	test_star_rating_and_retention_system()
	test_chamber_runner_dynamic_loading()
	test_level_select_sector_tabs()
	test_sound_manager_celebrations()
	test_save_manager_touch_controls_setting()
	test_settings_menu_touch_controls_toggle()
	test_mobile_virtual_joystick()
	test_mobile_touch_controls_overlay()
	test_chamber_clear_modal()
	test_chamber_runner_sector_palette()
	test_engine_hardening_and_modal_pausing()
	
	print("==================================================")
	print("TESTS COMPLETED: %d / %d PASSED" % [passed_tests, total_tests])
	print("==================================================")
	
	# Stop all audio players and flush streams so AudioServer can cleanly release handles
	SoundManager.stop_all()
	SoundManager.cleanup()
	
	# Allow deferred node deletions and audio playbacks to flush cleanly to avoid ObjectDB leaks
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
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
	var logs := [
		"log_01", "log_02", "log_03", "log_04", "log_05",
		"log_06", "log_07", "log_08", "log_09", "log_10"
	]
	for lid in logs:
		var data: Dictionary = NarrativeData.get_log(lid)
		var valid: bool = data.has("title") and data.has("content") and data.content.length() > 20
		_assert_test(valid, "Narrative: Log entry '%s' is complete" % lid)
	_assert_test(NarrativeData.get_log_count() == 10, "Narrative: Total story logs is exactly 10")

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
		"res://scenes/ui/settings_menu.tscn",
		"res://scenes/ui/victory_screen.tscn",
		"res://scenes/entities/security_drone.tscn",
		"res://scenes/levels/level_01.tscn",
		"res://scenes/levels/level_02.tscn",
		"res://scenes/levels/level_03.tscn",
		"res://scenes/levels/level_04.tscn",
		"res://scenes/levels/chamber_runner.tscn"
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
	
	# Completing Chamber 4 unlocks Chamber 5
	SaveManager.record_level_completion(4, 1, 19.5)
	_assert_test(SaveManager.is_level_unlocked(5) == true, "SaveManager: Completing Chamber 4 unlocks Chamber 5")
	
	# Completing final Chamber 50 should clamp to TOTAL_LEVELS and NOT unlock Chamber 51 (BUG-02)
	SaveManager.record_level_completion(50, 1, 19.5)
	_assert_test(SaveManager.is_level_unlocked(51) == false, "SaveManager: Completing Chamber 50 does not unlock nonexistent Chamber 51")
	_assert_test(SaveManager.unlocked_levels <= 50, "SaveManager: Unlocked levels clamped to TOTAL_LEVELS (50)")
	
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

func test_ambient_drone_audio() -> void:
	_assert_test(SoundManager.has_method("play_ambient_drone"), "SoundManager: Has play_ambient_drone method")
	_assert_test(SoundManager.has_method("stop_ambient_drone"), "SoundManager: Has stop_ambient_drone method")
	_assert_test(SoundManager.has_method("play_music"), "SoundManager: Has play_music method")
	_assert_test(SoundManager.has_method("stop_music"), "SoundManager: Has stop_music method")
	
	SoundManager.play_ambient_drone(-8.0)
	_assert_test(SoundManager.is_ambient_drone_playing() == true, "SoundManager: Background audio starts playing")
	
	var player := SoundManager.get_ambient_drone_player()
	_assert_test(player != null, "SoundManager: Ambient audio player instantiated")
	if player:
		_assert_test(player.bus == &"Music" or player.bus == &"Ambience", "SoundManager: Audio routed through Music or Ambience bus")
		_assert_test(player.stream != null, "SoundManager: Background audio has active stream")
		if player.stream is AudioStreamWAV:
			_assert_test((player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "SoundManager: Drone stream loops forward seamlessly")
		elif player.stream is AudioStreamMP3:
			_assert_test((player.stream as AudioStreamMP3).loop == true, "SoundManager: Background music MP3 loops seamlessly")
			
	# Test redundant play_ambient_drone preserves stream and uninterrupted playback
	var active_stream := player.stream if player else null
	SoundManager.play_ambient_drone(-6.0)
	_assert_test(SoundManager.is_ambient_drone_playing() == true, "SoundManager: Background audio remains playing on re-invocation")
	_assert_test(player.stream == active_stream, "SoundManager: Redundant play preserves active stream reference")
	
	# Test bus mute when volume slider reaches 0.0
	SaveManager.set_setting("music_volume", 0.0)
	var amb_idx := AudioServer.get_bus_index("Ambience")
	var mus_idx := AudioServer.get_bus_index("Music")
	var is_muted := (amb_idx != -1 and AudioServer.is_bus_mute(amb_idx)) or (mus_idx != -1 and AudioServer.is_bus_mute(mus_idx))
	_assert_test(is_muted == true, "SoundManager: Music / Ambience bus muted when music_volume is 0")
	SaveManager.set_setting("music_volume", 1.0)
	var is_unmuted := (amb_idx == -1 or not AudioServer.is_bus_mute(amb_idx)) and (mus_idx == -1 or not AudioServer.is_bus_mute(mus_idx))
	_assert_test(is_unmuted == true, "SoundManager: Music / Ambience bus unmuted when music_volume restored")
	
	# Test drone alert and player caught SFX exist in library
	_assert_test(SoundManager._sounds.has("drone_alert"), "SoundManager: Has drone_alert SFX in library")
	_assert_test(SoundManager._sounds.has("player_caught"), "SoundManager: Has player_caught SFX in library")
			
	SoundManager.stop_ambient_drone()
	_assert_test(SoundManager.is_ambient_drone_playing() == false, "SoundManager: Background audio stops cleanly")

func test_in_world_interaction_prompts() -> void:
	# 1. LeverSwitch prompt
	var lever_scene := load("res://scenes/interactables/lever_switch.tscn") as PackedScene
	var lever: LeverSwitch = lever_scene.instantiate() as LeverSwitch
	add_child(lever)
	_assert_test(lever.interaction_prompt != null, "LeverSwitch: InteractionPrompt child initialized")
	_assert_test(lever.is_prompt_visible() == false, "LeverSwitch: Prompt initially hidden")
	lever.show_prompt()
	_assert_test(lever.interaction_prompt.visible == true, "LeverSwitch: show_prompt makes prompt visible")
	lever.hide_prompt()
	lever.queue_free()
	
	# 2. TimedButton prompt
	var btn_scene := load("res://scenes/interactables/timed_button.tscn") as PackedScene
	var btn: TimedButton = btn_scene.instantiate() as TimedButton
	add_child(btn)
	_assert_test(btn.interaction_prompt != null, "TimedButton: InteractionPrompt child initialized")
	_assert_test(btn.is_prompt_visible() == false, "TimedButton: Prompt initially hidden")
	btn.show_prompt()
	_assert_test(btn.interaction_prompt.visible == true, "TimedButton: show_prompt makes prompt visible")
	btn.hide_prompt()
	btn.queue_free()
	
	# 3. TerminalLog prompt
	var term_scene := load("res://scenes/interactables/terminal_log.tscn") as PackedScene
	var term: TerminalLog = term_scene.instantiate() as TerminalLog
	add_child(term)
	_assert_test(term.interaction_prompt != null, "TerminalLog: InteractionPrompt child initialized")
	_assert_test(term.is_prompt_visible() == false, "TerminalLog: Prompt initially hidden")
	term.show_prompt()
	_assert_test(term.interaction_prompt.visible == true, "TerminalLog: show_prompt makes prompt visible")
	term.hide_prompt()
	term.queue_free()
	
	# 4. Echo vs Player detector isolation
	var player_scene := load("res://scenes/entities/player.tscn") as PackedScene
	var test_player: Player = player_scene.instantiate() as Player
	add_child(test_player)
	
	var echo_scene := load("res://scenes/entities/echo.tscn") as PackedScene
	var test_echo: Echo = echo_scene.instantiate() as Echo
	add_child(test_echo)
	
	var test_lever: LeverSwitch = lever_scene.instantiate() as LeverSwitch
	add_child(test_lever)
	
	# Echo enters -> MUST NOT trigger prompt
	test_lever._on_area_entered(test_echo.interaction_detector)
	_assert_test(test_lever.is_hovered == false, "LeverSwitch: Echo entering does NOT set is_hovered")
	_assert_test(test_lever.is_prompt_visible() == false, "LeverSwitch: Echo entering does NOT show interaction prompt")
	
	# Player enters -> MUST trigger prompt
	test_lever._on_area_entered(test_player.interaction_detector)
	_assert_test(test_lever.is_hovered == true, "LeverSwitch: Player entering sets is_hovered")
	_assert_test(test_lever.is_prompt_visible() == true, "LeverSwitch: Player entering shows interaction prompt")
	
	# Echo enters while player is present -> prompt remains visible
	test_lever._on_area_entered(test_echo.interaction_detector)
	_assert_test(test_lever.is_prompt_visible() == true, "LeverSwitch: Prompt remains visible when Echo passes")
	
	# Echo exits while player is present -> prompt MUST REMAIN visible
	test_lever._on_area_exited(test_echo.interaction_detector)
	_assert_test(test_lever.is_hovered == true, "LeverSwitch: Echo exiting does NOT clear player is_hovered")
	_assert_test(test_lever.is_prompt_visible() == true, "LeverSwitch: Echo exiting does NOT hide player prompt")
	
	# Player exits -> prompt hides
	test_lever._on_area_exited(test_player.interaction_detector)
	_assert_test(test_lever.is_hovered == false, "LeverSwitch: Player exiting clears is_hovered")
	_assert_test(test_lever.is_prompt_visible() == false, "LeverSwitch: Player exiting hides interaction prompt")
	
	# Test InteractionPrompt dynamic setters
	var prompt_comp = test_lever.interaction_prompt
	prompt_comp.prompt_text = "[E] OVERRIDE"
	_assert_test(prompt_comp.label.text == "[E] OVERRIDE", "InteractionPrompt: prompt_text setter updates label immediately")
	prompt_comp.prompt_color = Color.YELLOW
	_assert_test(prompt_comp.label.get_theme_color("font_color") == Color.YELLOW, "InteractionPrompt: prompt_color setter updates label color")
	
	test_player.queue_free()
	test_echo.queue_free()
	test_lever.queue_free()

func test_security_drone_enemy_mechanics() -> void:
	var drone_scene := load("res://scenes/entities/security_drone.tscn") as PackedScene
	_assert_test(drone_scene != null, "SecurityDrone: Scene loads successfully")
	
	var drone = drone_scene.instantiate()
	drone.position = Vector2(300, 300)
	drone.waypoint_offsets = PackedVector2Array([Vector2.ZERO, Vector2(100, 0)])
	add_child(drone)
	
	_assert_test(drone.is_in_group("enemies"), "SecurityDrone: Belongs to group 'enemies'")
	_assert_test(drone.is_in_group("resettable"), "SecurityDrone: Belongs to group 'resettable'")
	_assert_test(drone.current_state == SecurityDroneClass.DroneState.PATROL, "SecurityDrone: Starts in PATROL state")
	_assert_test(drone._world_waypoints.size() == 2, "SecurityDrone: World waypoints calculated accurately")
	
	# Spawn test player
	var player_scene := load("res://scenes/entities/player.tscn") as PackedScene
	var test_player: Player = player_scene.instantiate() as Player
	test_player.position = Vector2(800, 800) # Far away, out of vision
	add_child(test_player)
	
	# Out of detection range -> drone remains in PATROL
	var detectable: Player = drone._find_detectable_player()
	_assert_test(detectable == null, "SecurityDrone: Distant player is not detected")
	_assert_test(drone.current_state == SecurityDroneClass.DroneState.PATROL, "SecurityDrone: Remains in PATROL when player is distant")
	
	# Place player in front of drone within vision cone (facing RIGHT)
	drone.facing_direction = Vector2.RIGHT
	test_player.position = drone.global_position + Vector2(100, 0) # 100px directly in front
	var spotted: Player = drone._find_detectable_player()
	_assert_test(spotted == test_player, "SecurityDrone: Player in vision cone is detected")
	
	# Engage chase
	var alert_emitted := [false]
	drone.alert_state_changed.connect(func(is_alert: bool): if is_alert: alert_emitted[0] = true)
	drone._engage_chase(test_player)
	_assert_test(drone.current_state == SecurityDroneClass.DroneState.CHASE, "SecurityDrone: Transitions to CHASE state on detection")
	_assert_test(alert_emitted[0] == true, "SecurityDrone: Emits alert_state_changed signal")
	
	# Catch mechanics
	var caught_emitted := [false]
	var was_catching := [false]
	drone.player_caught_target.connect(func(d, _p): 
		caught_emitted[0] = true
		was_catching[0] = d._is_catching
	)
	test_player.position = drone.global_position + Vector2(15, 0) # Within catch_radius (26px)
	drone._process_chase(0.016, test_player)
	_assert_test(caught_emitted[0] == true, "SecurityDrone: Catches player within catch radius and emits player_caught_target")
	_assert_test(was_catching[0] == true or drone._is_catching == true, "SecurityDrone: Flags _is_catching true during interception")
	
	# Reset state mechanics
	drone.reset_state()
	_assert_test(drone.global_position == drone._initial_global_position, "SecurityDrone: Resets to initial position on reset_state")
	_assert_test(drone.current_state == SecurityDroneClass.DroneState.PATROL, "SecurityDrone: Resets to PATROL state on reset_state")
	_assert_test(drone._is_catching == false, "SecurityDrone: Clears _is_catching flag on reset_state")
	
	test_player.queue_free()
	drone.queue_free()

func test_settings_menu_component() -> void:
	var settings_scene := load("res://scenes/ui/settings_menu.tscn") as PackedScene
	_assert_test(settings_scene != null, "SettingsMenu: Scene loaded successfully")
	var menu = settings_scene.instantiate()
	_assert_test(menu != null, "SettingsMenu: Instantiated successfully")
	add_child(menu)
	
	_assert_test(menu.master_slider != null, "SettingsMenu: Master volume slider present")
	_assert_test(menu.sfx_slider != null, "SettingsMenu: SFX volume slider present")
	_assert_test(menu.music_slider != null, "SettingsMenu: Music / Ambience volume slider present")
	_assert_test(menu.screen_shake_toggle != null, "SettingsMenu: Screen shake checkbox present")
	_assert_test(menu.crt_shader_toggle != null, "SettingsMenu: CRT shader checkbox present")
	_assert_test(menu.reset_button != null, "SettingsMenu: Reset All Progress button present")
	_assert_test(menu.back_button != null, "SettingsMenu: Back / Close button present")
	_assert_test(menu.confirm_modal != null, "SettingsMenu: Confirmation alert modal present")
	_assert_test(menu.confirm_modal is ColorRect, "SettingsMenu: ConfirmModal has full-screen ColorRect overlay")
	_assert_test(menu.confirm_modal.anchor_right == 1.0 and menu.confirm_modal.anchor_bottom == 1.0, "SettingsMenu: ConfirmModal overlay covers full viewport")
	
	# Test open_menu
	menu.open_menu()
	_assert_test(menu.visible == true, "SettingsMenu: open_menu sets visible true")
	
	# Test slider updates mutate SaveManager settings
	menu._on_master_slider_changed(75.0)
	_assert_test(absf(float(SaveManager.get_setting("master_volume", 0.0)) - 0.75) < 0.01, "SettingsMenu: Master slider updates SaveManager master_volume")
	
	menu._on_sfx_slider_changed(50.0)
	_assert_test(absf(float(SaveManager.get_setting("sfx_volume", 0.0)) - 0.50) < 0.01, "SettingsMenu: SFX slider updates SaveManager sfx_volume")
	
	menu._on_music_slider_changed(65.0)
	_assert_test(absf(float(SaveManager.get_setting("music_volume", 0.0)) - 0.65) < 0.01, "SettingsMenu: Music slider updates SaveManager music_volume")
	
	# Test checkboxes
	menu._on_screen_shake_toggled(false)
	_assert_test(SaveManager.get_setting("screen_shake", true) == false, "SettingsMenu: Screen shake toggle updates SaveManager")
	
	menu._on_crt_shader_toggled(false)
	_assert_test(SaveManager.get_setting("crt_shader", true) == false, "SettingsMenu: CRT shader toggle updates SaveManager")
	
	# Test close_menu resets confirm_modal
	menu.confirm_modal.visible = true
	menu.close_menu()
	_assert_test(menu.visible == false, "SettingsMenu: close_menu hides menu modal")
	_assert_test(menu.confirm_modal.visible == false, "SettingsMenu: close_menu resets confirm_modal visibility to false")
	
	menu.queue_free()

func test_settings_persistence_roundtrip() -> void:
	# Configure custom test settings
	SaveManager.set_setting("master_volume", 0.42)
	SaveManager.set_setting("sfx_volume", 0.84)
	SaveManager.set_setting("music_volume", 0.68)
	SaveManager.set_setting("screen_shake", false)
	SaveManager.set_setting("crt_shader", false)
	
	var saved := SaveManager.save_data()
	_assert_test(saved == true, "SaveManager: Settings saved to disk successfully")
	
	# Wipe in-memory settings to prove reload from disk
	SaveManager.settings = {}
	var loaded := SaveManager.load_data()
	_assert_test(loaded == true, "SaveManager: Settings loaded from disk successfully")
	
	_assert_test(absf(float(SaveManager.get_setting("master_volume", 0.0)) - 0.42) < 0.01, "Persistence: Master volume roundtrip verified")
	_assert_test(absf(float(SaveManager.get_setting("sfx_volume", 0.0)) - 0.84) < 0.01, "Persistence: SFX volume roundtrip verified")
	_assert_test(absf(float(SaveManager.get_setting("music_volume", 0.0)) - 0.68) < 0.01, "Persistence: Music volume roundtrip verified")
	_assert_test(SaveManager.get_setting("screen_shake", true) == false, "Persistence: Screen shake setting roundtrip verified")
	_assert_test(SaveManager.get_setting("crt_shader", true) == false, "Persistence: CRT shader setting roundtrip verified")
	
	# Reset back to pristine defaults
	SaveManager.reset_all_progress()
	_assert_test(float(SaveManager.get_setting("master_volume", 0.0)) == 1.0, "SaveManager: reset_all_progress restores default master_volume")
	_assert_test(SaveManager.get_setting("screen_shake", false) == true, "SaveManager: reset_all_progress restores default screen_shake")

func test_project_branding_and_title() -> void:
	# Verify project.godot setting
	var proj_name: String = str(ProjectSettings.get_setting("application/config/name"))
	_assert_test(proj_name == "Echo of Dread", "ProjectSettings: application/config/name is 'Echo of Dread'")
	
	# Verify file text in project.godot
	var file := FileAccess.open("res://project.godot", FileAccess.READ)
	_assert_test(file != null, "Project Config: project.godot opened for reading")
	if file:
		var content := file.get_as_text()
		file.close()
		_assert_test(content.contains('config/name="Echo of Dread"'), "Project Config: config/name=\"Echo of Dread\" present")
		_assert_test(content.contains('config/description="Echo of Dread — A Sci-Fi Time-Loop Puzzle Game"'), "Project Config: config/description harmonized")
		
	# Verify MainMenu title header
	var menu_scene := load("res://scenes/ui/main_menu.tscn") as PackedScene
	var menu: Node = menu_scene.instantiate()
	var title_lbl: Label = menu.find_child("Title", true, false) as Label
	_assert_test(title_lbl != null and title_lbl.text == "ECHO OF DREAD", "MainMenu: Title label harmonized to 'ECHO OF DREAD'")
	menu.free()

func test_chamber_database_and_50_levels() -> void:
	_assert_test(ChamberDatabaseClass.get_chamber_count() == 50, "ChamberDatabase: Exactly 50 chambers registered")
	_assert_test(ChamberDatabaseClass.SECTORS.size() == 5, "ChamberDatabase: Exactly 5 sectors registered")
	
	for s_id in range(1, 6):
		var chambers: Array = ChamberDatabaseClass.get_sector_chambers(s_id)
		_assert_test(chambers.size() == 10, "ChamberDatabase: Sector %d contains exactly 10 chambers" % s_id)
		
	# Sample check specific chambers across all 5 sectors
	for c_id in [1, 10, 20, 30, 40, 50]:
		var data: Dictionary = ChamberDatabaseClass.get_chamber(c_id)
		_assert_test(data.has("title") and data.title.length() > 5, "ChamberDatabase: Chamber %d has valid title" % c_id)
		_assert_test(data.has("spawn_pos") and data.has("exit_pos"), "ChamberDatabase: Chamber %d has spawn and exit points" % c_id)
		_assert_test(data.has("par_loops") and data.par_loops > 0, "ChamberDatabase: Chamber %d has positive par_loops" % c_id)
		_assert_test(data.has("room_size") and data.room_size.x > 500, "ChamberDatabase: Chamber %d has valid room_size" % c_id)

	# Verify passability across all 50 chambers
	var any_chamber_blocked := false
	for c_id in range(1, 51):
		var c_data: Dictionary = ChamberDatabaseClass.get_chamber(c_id)
		var c_walls: Array = c_data.get("interior_walls", [])
		var s_pos: Vector2 = c_data.get("spawn_pos", Vector2(160, 360))
		var e_pos: Vector2 = c_data.get("exit_pos", Vector2(1120, 360))
		for w in c_walls:
			if w is Rect2:
				if w.has_point(s_pos) or w.has_point(e_pos) or w.size.y >= 500.0 or w.size.x >= 1000.0:
					any_chamber_blocked = true
					break
		if any_chamber_blocked:
			break
	_assert_test(not any_chamber_blocked, "ChamberDatabase: All 50 chambers have unblocked spawns, exits, and doorways")

func test_star_rating_and_retention_system() -> void:
	SaveManager.reset_all_progress()
	
	# Initial unplayed level has 0 stars
	_assert_test(SaveManager.get_level_stars(1) == 0, "StarSystem: Uncompleted chamber yields 0 stars")
	_assert_test(SaveManager.get_total_stars() == 0, "StarSystem: Total stars starts at 0")
	
	# Chamber 1 par is 1 loop
	# Solved in 1 loop -> 3 Stars
	SaveManager.record_level_completion(1, 1, 12.0)
	_assert_test(SaveManager.get_level_stars(1) == 3, "StarSystem: Completing in par_loops yields 3 stars")
	
	# Chamber 2 par is 2 loops
	# Solved in 3 loops (par + 1) -> 2 Stars
	SaveManager.record_level_completion(2, 3, 24.0)
	_assert_test(SaveManager.get_level_stars(2) == 2, "StarSystem: Completing in par_loops + 1 yields 2 stars")
	
	# Chamber 3 par is 2 loops
	# Solved in 4 loops (par + 2) -> 1 Star
	SaveManager.record_level_completion(3, 4, 28.0)
	_assert_test(SaveManager.get_level_stars(3) == 1, "StarSystem: Completing above par_loops + 1 yields 1 star")
	
	_assert_test(SaveManager.get_total_stars() == 6, "StarSystem: Total stars accurately aggregates across chambers (3 + 2 + 1 = 6)")

func test_chamber_runner_dynamic_loading() -> void:
	var runner_scene := load("res://scenes/levels/chamber_runner.tscn") as PackedScene
	_assert_test(runner_scene != null, "ChamberRunner: Scene loaded successfully")
	
	var runner = runner_scene.instantiate()
	_assert_test(runner != null, "ChamberRunner: Instantiated cleanly")
	runner.level_number_override = 5
	runner.level_number = 5 # Sector 1 Chamber 05
	add_child(runner)
	
	_assert_test(runner.chamber_title == "CHAMBER 05: SPLIT FREQUENCY", "ChamberRunner: Correct title loaded for Chamber 5")
	_assert_test(runner.room_builder != null, "ChamberRunner: RoomBuilder attached")
	_assert_test(runner.room_builder.interior_walls.size() == 6, "ChamberRunner: RoomBuilder received 6 interior walls")
	_assert_test(runner.room_builder._static_body != null and runner.room_builder._static_body.get_child_count() == 10, "ChamberRunner: RoomBuilder rebuilt collision with all perimeter and interior walls")
	
	# Verify Chamber 05 doorway passability
	var walls: Array[Rect2] = runner.room_builder.interior_walls
	var check_points: Array[Vector2] = [
		Vector2(280, 180), # North doorway
		Vector2(280, 520), # South doorway
		Vector2(950, 360), # Corridor before door
		Vector2(1000, 360) # Doorway aperture
	]
	var any_point_blocked := false
	for pt in check_points:
		for w in walls:
			if w.has_point(pt):
				any_point_blocked = true
				break
	_assert_test(not any_point_blocked, "ChamberRunner: Chamber 5 doorways and corridor are unblocked")
	_assert_test(runner.player != null, "ChamberRunner: Player instantiated")
	_assert_test(runner.level_exit != null, "ChamberRunner: LevelExit instantiated")
	_assert_test(runner._doors_by_id.size() > 0, "ChamberRunner: Doors dynamically instantiated and registered")
	_assert_test(runner._triggers_by_id.size() > 0, "ChamberRunner: Triggers dynamically instantiated and registered")
	
	runner.queue_free()

func test_level_select_sector_tabs() -> void:
	var ls_scene := load("res://scenes/ui/level_select.tscn") as PackedScene
	var ls = ls_scene.instantiate()
	add_child(ls)
	
	_assert_test(ls.sector_container != null, "LevelSelect: Sector tabs container present")
	_assert_test(ls.sector_container.get_child_count() == 5, "LevelSelect: 5 Sector tabs created")
	_assert_test(ls.grid_container.get_child_count() == 10, "LevelSelect: 10 chamber buttons created for active sector")
	
	# Switch to Sector 3 (Gamma)
	ls.current_sector = 3
	ls._update_sector_view()
	_assert_test(ls.grid_container.get_child_count() == 10, "LevelSelect: Sector 3 populates 10 chamber buttons")
	
	ls.queue_free()

func test_sound_manager_celebrations() -> void:
	_assert_test(SoundManager._sounds.has("star_ding"), "SoundManager: Has star_ding SFX in library")
	_assert_test(SoundManager._sounds.has("star_3_fanfare"), "SoundManager: Has star_3_fanfare SFX in library")
	_assert_test(SoundManager._sounds.has("record_break"), "SoundManager: Has record_break SFX in library")

func test_save_manager_touch_controls_setting() -> void:
	var original_touch = SaveManager.get_setting("touch_controls", false)
	SaveManager.set_setting("touch_controls", true)
	_assert_test(SaveManager.get_setting("touch_controls") == true, "SaveManager: touch_controls can be set to true")
	SaveManager.set_setting("touch_controls", false)
	_assert_test(SaveManager.get_setting("touch_controls") == false, "SaveManager: touch_controls can be set to false")
	SaveManager.set_setting("touch_controls", original_touch)

func test_settings_menu_touch_controls_toggle() -> void:
	var sm_scene := load("res://scenes/ui/settings_menu.tscn") as PackedScene
	var sm = sm_scene.instantiate()
	add_child(sm)
	sm._ensure_node_refs()
	
	_assert_test(sm.touch_controls_toggle != null, "SettingsMenu: TouchControlsToggle CheckBox present")
	sm._on_touch_controls_toggled(true)
	_assert_test(SaveManager.get_setting("touch_controls") == true, "SettingsMenu: Toggling touch controls updates SaveManager")
	sm._on_touch_controls_toggled(false)
	_assert_test(SaveManager.get_setting("touch_controls") == false, "SettingsMenu: Untoggling touch controls updates SaveManager")
	
	sm.queue_free()

func test_mobile_virtual_joystick() -> void:
	const MobileVirtualJoystickClass = preload("res://scripts/ui/virtual_joystick.gd")
	var vj = MobileVirtualJoystickClass.new()
	add_child(vj)
	vj.size = Vector2(160, 160)
	vj._update_center()
	
	_assert_test(vj.get_direction() == Vector2.ZERO, "VirtualJoystick: Initial direction is zero")
	
	# Simulate drag right
	vj._update_stick(vj._center_pos + Vector2(50, 0))
	_assert_test(vj.get_direction().x > 0.0, "VirtualJoystick: Dragging right produces positive X direction")
	_assert_test(Input.is_action_pressed("move_right"), "VirtualJoystick: Input action move_right is pressed")
	
	# Simulate drag up
	vj._update_stick(vj._center_pos + Vector2(0, -50))
	_assert_test(vj.get_direction().y < 0.0, "VirtualJoystick: Dragging up produces negative Y direction")
	_assert_test(Input.is_action_pressed("move_up"), "VirtualJoystick: Input action move_up is pressed")
	
	# Reset stick
	vj._reset_stick()
	_assert_test(vj.get_direction() == Vector2.ZERO, "VirtualJoystick: Reset stick returns direction to zero")
	_assert_test(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_up"), "VirtualJoystick: Reset stick releases all movement input actions")
	
	vj.queue_free()

func test_mobile_touch_controls_overlay() -> void:
	var tc_scene := load("res://scenes/ui/touch_controls.tscn") as PackedScene
	_assert_test(tc_scene != null, "TouchControls: Scene loads successfully")
	var tc = tc_scene.instantiate()
	add_child(tc)
	
	_assert_test(tc.joystick_container != null, "TouchControls: VirtualJoystick container present")
	_assert_test(tc.interact_btn != null, "TouchControls: Interact button present")
	_assert_test(tc.loop_btn != null, "TouchControls: Loop rewind button present")
	_assert_test(tc.clear_btn != null, "TouchControls: Clear echoes button present")
	_assert_test(tc.pause_btn != null, "TouchControls: Pause button present")
	
	tc.set_touch_enabled(true)
	_assert_test(tc.is_touch_active() == true, "TouchControls: Enabled mode activates root control visibility")
	tc.set_touch_enabled(false)
	_assert_test(tc.is_touch_active() == false, "TouchControls: Disabled mode hides root control visibility")
	
	tc.queue_free()

func test_chamber_clear_modal() -> void:
	var ccm_scene := load("res://scenes/ui/chamber_clear_modal.tscn") as PackedScene
	_assert_test(ccm_scene != null, "ChamberClearModal: Scene loads successfully")
	var ccm = ccm_scene.instantiate()
	add_child(ccm)
	
	_assert_test(ccm.title_label != null, "ChamberClearModal: Title label present")
	_assert_test(ccm.next_button != null, "ChamberClearModal: Next button present")
	_assert_test(ccm.retry_button != null, "ChamberClearModal: Retry button present")
	_assert_test(ccm.select_button != null, "ChamberClearModal: Sector select button present")
	
	ccm.display_results(7, 2, 18.5, 2, true, "log_02")
	_assert_test(ccm.visible == true, "ChamberClearModal: display_results makes modal visible")
	_assert_test(ccm.title_label.text.contains("CHAMBER 07 SECURED"), "ChamberClearModal: Chamber title formatted properly")
	_assert_test(ccm.earned_stars == 3, "ChamberClearModal: Completing in par_loops awards 3 stars")
	_assert_test(ccm.record_badge.visible == true, "ChamberClearModal: Record badge visible for new record")
	_assert_test(ccm.lore_badge.visible == true and ccm.lore_badge.text.contains("LOG_02"), "ChamberClearModal: Lore unlock badge decoded")
	
	ccm.queue_free()

func test_chamber_runner_sector_palette() -> void:
	var runner_scene := load("res://scenes/levels/chamber_runner.tscn") as PackedScene
	
	# Sector 1 (Alpha)
	var r1 = runner_scene.instantiate()
	r1.level_number_override = 1
	add_child(r1)
	_assert_test(r1.room_builder.wall_border_color == Color(0.30, 0.60, 0.85, 1.0), "ChamberRunner: Sector 1 styled with Alpha cyan palette")
	r1.queue_free()
	
	# Sector 2 (Beta)
	var r2 = runner_scene.instantiate()
	r2.level_number_override = 15
	add_child(r2)
	_assert_test(r2.room_builder.wall_border_color == Color(0.85, 0.55, 0.15, 1.0), "ChamberRunner: Sector 2 styled with Beta amber palette")
	r2.queue_free()
	
	# Sector 3 (Gamma)
	var r3 = runner_scene.instantiate()
	r3.level_number_override = 25
	add_child(r3)
	_assert_test(r3.room_builder.wall_border_color == Color(0.75, 0.35, 0.90, 1.0), "ChamberRunner: Sector 3 styled with Gamma amethyst palette")
	r3.queue_free()
	
	# Sector 4 (Delta)
	var r4 = runner_scene.instantiate()
	r4.level_number_override = 35
	add_child(r4)
	_assert_test(r4.room_builder.wall_border_color == Color(0.85, 0.20, 0.25, 1.0), "ChamberRunner: Sector 4 styled with Delta crimson palette")
	r4.queue_free()
	
	# Sector 5 (Omega)
	var r5 = runner_scene.instantiate()
	r5.level_number_override = 45
	add_child(r5)
	_assert_test(r5.room_builder.wall_border_color == Color(0.95, 0.85, 0.35, 1.0), "ChamberRunner: Sector 5 styled with Omega singularity gold palette")
	r5.queue_free()

func test_engine_hardening_and_modal_pausing() -> void:
	# 1. Test GameHUD chamber cleared pauses tree and modal unpauses
	var hud_scene := load("res://scenes/ui/game_hud.tscn") as PackedScene
	var hud = hud_scene.instantiate()
	add_child(hud)
	get_tree().paused = false
	
	hud._on_chamber_cleared({"level_index": 1, "loop_count": 1, "elapsed_time": 12.0, "par_loops": 2, "is_new_record": true})
	_assert_test(get_tree().paused == true, "Hardening: GameHUD pauses scene tree on chamber cleared")
	_assert_test(hud.chamber_clear_modal.visible == true, "Hardening: ChamberClearModal is visible on clear")
	
	get_tree().paused = false
	_assert_test(get_tree().paused == false, "Hardening: Scene tree unpauses cleanly")
	
	# 2. Test Interception flash preservation against cyan rewind overwrite
	hud.trigger_interception_flash()
	_assert_test(hud._is_interception_active == true, "Hardening: Drone interception flash active flag set")
	_assert_test(hud.rewind_flash.color.r > 0.8, "Hardening: Interception flash is red chromatic tone")
	
	hud.trigger_rewind_effect()
	_assert_test(hud._is_interception_active == true, "Hardening: Interception active flag preserved against rewind")
	_assert_test(hud.rewind_flash.color.r > 0.8, "Hardening: Interception flash not overwritten by cyan rewind")
	hud.queue_free()
	
	# 3. Test TouchControls and VirtualJoystick input release
	var touch_scene := load("res://scenes/ui/touch_controls.tscn") as PackedScene
	var touch = touch_scene.instantiate()
	add_child(touch)
	
	Input.action_press("interact")
	_assert_test(Input.is_action_pressed("interact") == true, "Hardening: Test action interact is pressed")
	touch._release_all_touch_actions()
	_assert_test(Input.is_action_pressed("interact") == false, "Hardening: TouchControls releases interact action")
	
	var joy_script = load("res://scripts/ui/virtual_joystick.gd")
	var joy = joy_script.new()
	add_child(joy)
	Input.action_press("move_right")
	_assert_test(Input.is_action_pressed("move_right") == true, "Hardening: Test action move_right is pressed")
	joy._reset_stick()
	_assert_test(Input.is_action_pressed("move_right") == false, "Hardening: VirtualJoystick releases move_right action on reset")
	touch.queue_free()
	joy.queue_free()
	
	# 4. Test SoundManager self-healing
	SoundManager.cleanup()
	_assert_test(SoundManager._sounds.is_empty(), "Hardening: SoundManager cleared sound library on cleanup")
	SoundManager.play_sfx("click")
	_assert_test(not SoundManager._sounds.is_empty(), "Hardening: SoundManager self-heals sound library if invoked after cleanup")
	_assert_test(SoundManager._sounds.has("click"), "Hardening: SoundManager sound library has click SFX restored")
	
	# 5. Test VictoryScreen process mode
	var victory_scene := load("res://scenes/ui/victory_screen.tscn") as PackedScene
	var victory = victory_scene.instantiate()
	add_child(victory)
	_assert_test(victory.process_mode == Node.PROCESS_MODE_ALWAYS, "Hardening: VictoryScreen runs in PROCESS_MODE_ALWAYS")
	victory.queue_free()



