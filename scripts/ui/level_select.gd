class_name LevelSelect
extends Control

@onready var btn_level_1: Button = $GridContainer/Level1Button
@onready var btn_level_2: Button = $GridContainer/Level2Button
@onready var btn_level_3: Button = $GridContainer/Level3Button
@onready var btn_level_4: Button = $GridContainer/Level4Button
@onready var back_button: Button = $BackButton

func _ready() -> void:
	_update_buttons()
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _update_buttons() -> void:
	var buttons: Array[Button] = [btn_level_1, btn_level_2, btn_level_3, btn_level_4]
	var chamber_names := [
		"01: RESONANCE",
		"02: ISOLATION",
		"03: THE VAULT",
		"04: THE CORE"
	]
	
	for i in range(buttons.size()):
		var btn := buttons[i]
		if not btn:
			continue
		var lvl_num := i + 1
		var is_unlocked := true
		if SaveManager:
			is_unlocked = SaveManager.is_level_unlocked(lvl_num)
			
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)
			
		btn.disabled = not is_unlocked
		if is_unlocked:
			var best_loops := 0
			if SaveManager:
				best_loops = SaveManager.get_best_loops(lvl_num)
			if best_loops > 0:
				btn.text = "CHAMBER %s\n★ BEST: %d LOOPS" % [chamber_names[i], best_loops]
			else:
				btn.text = "CHAMBER %s\nUNLOCKED" % chamber_names[i]
			btn.pressed.connect(func(): _load_level(lvl_num))
		else:
			btn.text = "CHAMBER %s\n[LOCKED]" % chamber_names[i]

func _load_level(idx: int) -> void:
	SoundManager.play_sfx("click")
	GameManager.load_level(idx)

func _on_back_pressed() -> void:
	SoundManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
