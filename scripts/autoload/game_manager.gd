extends Node

# GameManager: Global state, level flow, input mappings, and game coordination

signal level_started(level_index: int)
signal level_completed(level_index: int)
signal narrative_opened(log_data: Dictionary)
signal narrative_closed
signal loop_reset_requested
signal echoes_cleared_requested

const TOTAL_LEVELS: int = 4

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
	var scene_path: String = LEVEL_SCENE_PATHS.get(current_level_index, "res://scenes/ui/main_menu.tscn")
	var err := get_tree().change_scene_to_file(scene_path)
	if err == OK:
		_emit_level_started_deferred.call_deferred(current_level_index)
	else:
		printerr("GameManager: Failed to load scene: %s (Error %d)" % [scene_path, err])

func _emit_level_started_deferred(idx: int) -> void:
	level_started.emit(idx)

func restart_current_level() -> void:
	load_level(current_level_index)

func complete_level(loop_count: int = 1, elapsed_time: float = 0.0) -> void:
	if SaveManager:
		SaveManager.record_level_completion(current_level_index, loop_count, elapsed_time)
	level_completed.emit(current_level_index)
	SoundManager.play_sfx("level_win")
	if current_level_index < TOTAL_LEVELS:
		load_level(current_level_index + 1)
	else:
		get_tree().change_scene_to_file("res://scenes/ui/victory_screen.tscn")

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
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
