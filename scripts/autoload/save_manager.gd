extends Node

# SaveManager: Global progression, high-score / best loop tracking, and settings persistence.
# Saves to user://savegame.json with graceful fallback and validation.

signal progress_updated
signal settings_changed

const SAVE_FILE_PATH: String = "user://savegame.json"

var unlocked_levels: int = 1
var best_loop_counts: Dictionary = {}  # { level_index (int): best_loops (int) }
var best_times: Dictionary = {}        # { level_index (int): best_time_sec (float) }
var discovered_lore: Array[String] = []
var settings: Dictionary = {
	"master_volume": 1.0,
	"sfx_volume": 1.0,
	"music_volume": 1.0,
	"screen_shake": true,
	"crt_shader": true
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_data()

func is_level_unlocked(level_idx: int) -> bool:
	return level_idx <= unlocked_levels

func unlock_level(level_idx: int) -> void:
	if level_idx > unlocked_levels:
		unlocked_levels = level_idx
		save_data()
		progress_updated.emit()

func record_level_completion(level_idx: int, loop_count: int, elapsed_time: float) -> void:
	# Update best loops
	if not best_loop_counts.has(level_idx) or loop_count < best_loop_counts[level_idx]:
		best_loop_counts[level_idx] = loop_count
		
	# Update best time
	if not best_times.has(level_idx) or elapsed_time < best_times[level_idx]:
		best_times[level_idx] = elapsed_time
		
	# Automatically unlock next chamber
	unlock_level(level_idx + 1)
	save_data()
	progress_updated.emit()

func get_best_loops(level_idx: int) -> int:
	if best_loop_counts.has(level_idx):
		return int(best_loop_counts[level_idx])
	if best_loop_counts.has(str(level_idx)):
		return int(best_loop_counts[str(level_idx)])
	return 0

func get_best_time(level_idx: int) -> float:
	if best_times.has(level_idx):
		return float(best_times[level_idx])
	if best_times.has(str(level_idx)):
		return float(best_times[str(level_idx)])
	return 0.0

func record_lore_discovered(log_id: String) -> void:
	if not discovered_lore.has(log_id):
		discovered_lore.append(log_id)
		save_data()
		progress_updated.emit()

func is_lore_discovered(log_id: String) -> bool:
	return discovered_lore.has(log_id)

func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	save_data()
	settings_changed.emit()

func get_setting(key: String, default_value: Variant = null) -> Variant:
	return settings.get(key, default_value)

func save_data() -> bool:
	var save_dict := {
		"version": 1,
		"unlocked_levels": unlocked_levels,
		"best_loop_counts": best_loop_counts,
		"best_times": best_times,
		"discovered_lore": discovered_lore,
		"settings": settings
	}
	
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		printerr("SaveManager: Failed to open %s for writing. Error: %d" % [SAVE_FILE_PATH, FileAccess.get_open_error()])
		return false
		
	var json_str := JSON.stringify(save_dict, "\t")
	file.store_string(json_str)
	file.close()
	return true

func load_data() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		# Default state
		return false
		
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		printerr("SaveManager: Failed to open %s for reading." % SAVE_FILE_PATH)
		return false
		
	var content := file.get_as_text()
	file.close()
	
	var test_json := JSON.new()
	var parse_result := test_json.parse(content)
	if parse_result != OK:
		printerr("SaveManager: JSON parse error in save file: %s" % test_json.get_error_message())
		return false
		
	var data: Dictionary = test_json.data
	if data.has("unlocked_levels"):
		unlocked_levels = int(data["unlocked_levels"])
		
	if data.has("best_loop_counts") and data["best_loop_counts"] is Dictionary:
		best_loop_counts.clear()
		for k in data["best_loop_counts"]:
			best_loop_counts[int(k)] = int(data["best_loop_counts"][k])
			
	if data.has("best_times") and data["best_times"] is Dictionary:
		best_times.clear()
		for k in data["best_times"]:
			best_times[int(k)] = float(data["best_times"][k])
			
	if data.has("discovered_lore") and data["discovered_lore"] is Array:
		discovered_lore.clear()
		for lid in data["discovered_lore"]:
			discovered_lore.append(str(lid))
			
	if data.has("settings") and data["settings"] is Dictionary:
		for k in data["settings"]:
			settings[k] = data["settings"][k]
			
	return true

func reset_settings() -> void:
	settings = {
		"master_volume": 1.0,
		"sfx_volume": 1.0,
		"music_volume": 1.0,
		"screen_shake": true,
		"crt_shader": true
	}
	settings_changed.emit()

func reset_all_progress() -> void:
	unlocked_levels = 1
	best_loop_counts.clear()
	best_times.clear()
	discovered_lore.clear()
	reset_settings()
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	progress_updated.emit()
