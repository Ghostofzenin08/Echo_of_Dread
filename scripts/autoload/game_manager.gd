extends Node

# GameManager: Global state, level flow, input mappings, and game coordination

signal level_started(level_index: int)
signal level_completed(level_index: int)
signal narrative_opened(log_data: Dictionary)
signal narrative_closed
signal loop_reset_requested
signal echoes_cleared_requested
signal chamber_cleared(clear_data: Dictionary)

const TOTAL_LEVELS: int = 50

var current_level_index: int = 1
var is_narrative_open: bool = false
var is_paused: bool = false

const LEVEL_SCENE_PATHS: Dictionary = {
	1: "res://scenes/levels/level_01.tscn",
	2: "res://scenes/levels/level_02.tscn",
	3: "res://scenes/levels/level_03.tscn",
	4: "res://scenes/levels/level_04.tscn",
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_default_input_map()

func _setup_default_input_map() -> void:
	_register_action("move_left", [KEY_A, KEY_LEFT])
	_register_action("move_right", [KEY_D, KEY_RIGHT])
	_register_action("move_up", [KEY_W, KEY_UP])
	_register_action("move_down", [KEY_S, KEY_DOWN])
	_register_action("interact", [KEY_E, KEY_SPACE, KEY_ENTER])
	_register_action("reset_loop", [KEY_R])
	_register_action("clear_echoes", [KEY_C, KEY_BACKSPACE])
	_register_action("pause", [KEY_ESCAPE, KEY_P])

func _register_action(action_name: String, key_codes: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key_code in key_codes:
		var event := InputEventKey.new()
		event.physical_keycode = key_code
		# Also set keycode for cross-platform fallback
		event.keycode = key_code
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)

func start_game() -> void:
	load_level(1)

func load_level(level_idx: int) -> void:
	current_level_index = clampi(level_idx, 1, TOTAL_LEVELS)
	var scene_path: String = LEVEL_SCENE_PATHS.get(current_level_index, "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		scene_path = "res://scenes/levels/chamber_runner.tscn"
	var err := get_tree().change_scene_to_file(scene_path)
	if err == OK:
		_emit_level_started_deferred.call_deferred(current_level_index)
	else:
		printerr("GameManager: Failed to load scene: %s (Error %d)" % [scene_path, err])

func _emit_level_started_deferred(idx: int) -> void:
	level_started.emit(idx)

func restart_current_level() -> void:
	load_level(current_level_index)

func complete_level(loop_count: int = 1, elapsed_time: float = 0.0, show_modal: bool = true) -> void:
	var prev_best_loops := 0
	if SaveManager:
		prev_best_loops = SaveManager.get_best_loops(current_level_index)
	var is_new_record: bool = prev_best_loops <= 0 or loop_count < prev_best_loops
	
	if SaveManager:
		SaveManager.record_level_completion(current_level_index, loop_count, elapsed_time)
		
	level_completed.emit(current_level_index)
	SoundManager.play_sfx("level_win")
	
	var par := 2
	if ResourceLoader.exists("res://scripts/world/chamber_database.gd"):
		var db_class = load("res://scripts/world/chamber_database.gd")
		if db_class and db_class.has_method("get_par_loops"):
			par = db_class.get_par_loops(current_level_index)
			
	var clear_data := {
		"level_index": current_level_index,
		"loop_count": loop_count,
		"elapsed_time": elapsed_time,
		"par_loops": par,
		"is_new_record": is_new_record
	}
	chamber_cleared.emit(clear_data)
	
	if not show_modal:
		advance_to_next_level()

func advance_to_next_level() -> void:
	if current_level_index < TOTAL_LEVELS:
		load_level(current_level_index + 1)
	else:
		SoundManager.stop_ambient_drone()
		get_tree().change_scene_to_file("res://scenes/ui/victory_screen.tscn")

func open_level_select() -> void:
	is_paused = false
	is_narrative_open = false
	get_tree().paused = false
	SoundManager.stop_ambient_drone()
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func open_narrative(log_id: String) -> void:
	if SaveManager:
		SaveManager.record_lore_discovered(log_id)
	var log_data: Dictionary = NarrativeData.get_log(log_id)
	is_narrative_open = true
	narrative_opened.emit(log_data)
	SoundManager.play_sfx("terminal_beep")

func close_narrative() -> void:
	is_narrative_open = false
	narrative_closed.emit()
	SoundManager.play_sfx("click")

func return_to_main_menu() -> void:
	is_paused = false
	is_narrative_open = false
	get_tree().paused = false
	SoundManager.stop_ambient_drone()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
