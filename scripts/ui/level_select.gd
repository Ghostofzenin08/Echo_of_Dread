class_name LevelSelect
extends Control

# LevelSelect: Sector-paginated level selection interface for all 50 Chambers across 5 Sectors.
# Features 3-Star loop efficiency ratings, best times, and responsive cyber-tactile buttons.

const ChamberDatabaseClass = preload("res://scripts/world/chamber_database.gd")

@onready var title_label: Label = $Title
@onready var star_count_label: Label = get_node_or_null("StarCountLabel")
@onready var sector_container: HBoxContainer = get_node_or_null("SectorContainer")
@onready var grid_container: GridContainer = $GridContainer
@onready var back_button: Button = $BackButton

var current_sector: int = 1

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	_setup_sector_tabs()
	_update_sector_view()

func _setup_sector_tabs() -> void:
	if not sector_container:
		return
	for child in sector_container.get_children():
		sector_container.remove_child(child)
		child.queue_free()
		
	for s_id in range(1, 6):
		var tab_btn := Button.new()
		tab_btn.name = "SectorBtn%d" % s_id
		var s_data: Dictionary = ChamberDatabaseClass.SECTORS.get(s_id, {})
		var s_name: String = s_data.get("name", "SECTOR %d" % s_id)
		var short_name: String = s_name.replace("SECTOR ", "SEC ")
		tab_btn.text = short_name
		tab_btn.custom_minimum_size = Vector2(160, 44)
		tab_btn.pressed.connect(func():
			current_sector = s_id
			SoundManager.play_sfx("click")
			_update_sector_view()
		)
		sector_container.add_child(tab_btn)

func _update_sector_view() -> void:
	if star_count_label and SaveManager:
		var stars := SaveManager.get_total_stars()
		star_count_label.text = "★ CHRONAL STARS: %d / 150" % stars
		
	# Update sector buttons highlight
	if sector_container:
		for i in range(sector_container.get_child_count()):
			var btn := sector_container.get_child(i) as Button
			var s_id := i + 1
			if s_id == current_sector:
				btn.modulate = Color(0.2, 0.9, 1.0, 1.0)
			else:
				btn.modulate = Color(0.7, 0.75, 0.85, 0.8)
				
	# Clear & populate grid
	if not grid_container:
		return
		
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()
		
	var chambers: Array = ChamberDatabaseClass.get_sector_chambers(current_sector)
	grid_container.columns = 5
	
	for c_id in chambers:
		var c_data: Dictionary = ChamberDatabaseClass.get_chamber(c_id)
		var btn := Button.new()
		btn.name = "ChamberBtn%d" % c_id
		btn.custom_minimum_size = Vector2(180, 80)
		
		var is_unlocked := true
		if SaveManager:
			is_unlocked = SaveManager.is_level_unlocked(c_id)
			
		btn.disabled = not is_unlocked
		if is_unlocked:
			var stars := 0
			var best_loops := 0
			var best_time := 0.0
			if SaveManager:
				stars = SaveManager.get_level_stars(c_id)
				best_loops = SaveManager.get_best_loops(c_id)
				best_time = SaveManager.get_best_time(c_id)
				
			var star_str := ""
			for s in range(stars):
				star_str += "★"
			for s in range(3 - stars):
				star_str += "☆"
				
			var c_title: String = c_data.get("title", "CHAMBER %02d" % c_id)
			if c_title.begins_with("CHAMBER "):
				c_title = c_title.substr(8)
				
			if best_loops > 0:
				btn.text = "%s\n%s\n%d LOOPS (%.1fs)" % [c_title, star_str, best_loops, best_time]
			else:
				btn.text = "%s\n%s\nREADY" % [c_title, star_str]
			btn.pressed.connect(func(): _load_level(c_id))
		else:
			btn.text = "CHAMBER %02d\n[LOCKED]" % c_id
			
		grid_container.add_child(btn)

func _load_level(idx: int) -> void:
	SoundManager.play_sfx("click")
	GameManager.load_level(idx)

func _on_back_pressed() -> void:
	SoundManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
