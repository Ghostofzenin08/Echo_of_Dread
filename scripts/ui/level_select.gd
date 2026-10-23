class_name LevelSelect
extends Control

# LevelSelect: Paginated level selection interface for all 50 Chambers.
# Conforms to Figma design (Node 225:177) with slide carousel, lock status,
# chamber stats, and strictly "Post No Bills Colombo Light" typography.

const ChamberDatabaseClass = preload("res://scripts/world/chamber_database.gd")

@onready var title_label: Label = get_node_or_null("Title")
@onready var slide_info_label: Label = get_node_or_null("SlideFooter")
@onready var star_count_label: Label = get_node_or_null("StarCountLabel")
@onready var back_button: Button = $BackButton
@onready var prev_button: TextureButton = $PrevButton
@onready var next_button: TextureButton = $NextButton
@onready var help_button: Button = get_node_or_null("HelpButton")
@onready var guide_modal: Control = get_node_or_null("GuideModal")

# Left card
@onready var card_left_container: VBoxContainer = $CardsContainer/CardLeft
@onready var btn_left: Button = $CardsContainer/CardLeft/Button
@onready var bg_left: TextureRect = $CardsContainer/CardLeft/Button/Bg
@onready var content_left: VBoxContainer = $CardsContainer/CardLeft/Button/Content
@onready var title_left: Label = $CardsContainer/CardLeft/Button/Content/ChamberName
@onready var sector_left: Label = $CardsContainer/CardLeft/Button/Content/SectorName
@onready var stars_left: Label = $CardsContainer/CardLeft/Button/Content/Stars
@onready var stats_left: Label = $CardsContainer/CardLeft/Button/Content/Stats
@onready var lock_left: TextureRect = $CardsContainer/CardLeft/Button/LockIcon
@onready var lbl_level_left: Label = $CardsContainer/CardLeft/LevelLabel

# Right card
@onready var card_right_container: VBoxContainer = $CardsContainer/CardRight
@onready var btn_right: Button = $CardsContainer/CardRight/Button
@onready var bg_right: TextureRect = $CardsContainer/CardRight/Button/Bg
@onready var content_right: VBoxContainer = $CardsContainer/CardRight/Button/Content
@onready var title_right: Label = $CardsContainer/CardRight/Button/Content/ChamberName
@onready var sector_right: Label = $CardsContainer/CardRight/Button/Content/SectorName
@onready var stars_right: Label = $CardsContainer/CardRight/Button/Content/Stars
@onready var stats_right: Label = $CardsContainer/CardRight/Button/Content/Stats
@onready var lock_right: TextureRect = $CardsContainer/CardRight/Button/LockIcon
@onready var lbl_level_right: Label = $CardsContainer/CardRight/LevelLabel

const TOTAL_LEVELS := 50
const LEVELS_PER_SLIDE := 2
const TOTAL_SLIDES := 25 # 50 / 2

var current_slide: int = 1 # 1 to 25
var _hover_tweens: Dictionary = {}

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		_setup_hover_effect(back_button, Vector2(1.04, 1.04))
		
	if prev_button:
		prev_button.pressed.connect(_on_prev_pressed)
		_setup_hover_effect(prev_button, Vector2(1.08, 1.08))
		
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
		_setup_hover_effect(next_button, Vector2(1.08, 1.08))
		
	if help_button:
		help_button.pressed.connect(_on_help_pressed)
		_setup_hover_effect(help_button, Vector2(1.08, 1.08))

	if guide_modal:
		var guide_back := guide_modal.find_child("BackButton", true, false) as Button
		if guide_back:
			guide_back.pressed.connect(func():
				SoundManager.play_sfx("click")
				guide_modal.visible = false
			)
		guide_modal.visible = false
		
	if btn_left:
		_setup_hover_effect(btn_left, Vector2(1.025, 1.025))
	if btn_right:
		_setup_hover_effect(btn_right, Vector2(1.025, 1.025))
		
	# Find first unlocked level to default to appropriate slide
	_select_default_slide()
	_update_view()

func _select_default_slide() -> void:
	current_slide = 1
	if SaveManager:
		# Check highest unlocked level
		for lvl in range(TOTAL_LEVELS, 0, -1):
			if SaveManager.is_level_unlocked(lvl):
				current_slide = ((lvl - 1) / LEVELS_PER_SLIDE) + 1
				break

func _setup_hover_effect(control: Control, hover_scale: Vector2) -> void:
	control.pivot_offset = control.size * 0.5
	control.resized.connect(func(): control.pivot_offset = control.size * 0.5)
	control.mouse_entered.connect(func(): _animate_scale(control, hover_scale, 1.15))
	control.mouse_exited.connect(func(): _animate_scale(control, Vector2.ONE, 1.0))
	control.focus_entered.connect(func(): _animate_scale(control, hover_scale, 1.15))
	control.focus_exited.connect(func(): _animate_scale(control, Vector2.ONE, 1.0))

func _animate_scale(ctrl: Control, target_scale: Vector2, target_modulate: float) -> void:
	if not is_instance_valid(ctrl):
		return
	if _hover_tweens.has(ctrl) and is_instance_valid(_hover_tweens[ctrl]):
		_hover_tweens[ctrl].kill()
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hover_tweens[ctrl] = tw
	tw.tween_property(ctrl, "scale", target_scale, 0.15)
	tw.tween_property(ctrl, "modulate:v", target_modulate, 0.15)

func _update_view() -> void:
	# Update Slide & Star counts
	var lvl_left := (current_slide - 1) * LEVELS_PER_SLIDE + 1
	var lvl_right := lvl_left + 1
	
	var sector_id := ChamberDatabaseClass.get_sector_id(lvl_left)
	var sector_name := ChamberDatabaseClass.get_sector_name(sector_id)
	
	if slide_info_label:
		slide_info_label.text = "SLIDE %d / %d  •  %s  (CHAMBERS %d - %d)" % [
			current_slide, TOTAL_SLIDES, sector_name, lvl_left, mini(lvl_right, TOTAL_LEVELS)
		]
		
	if star_count_label and SaveManager:
		var stars := SaveManager.get_total_stars()
		star_count_label.text = "★ CHRONAL STARS: %d / 150" % stars
		
	# Arrow visibility
	if prev_button:
		prev_button.visible = current_slide > 1
	if next_button:
		next_button.visible = current_slide < TOTAL_SLIDES
		
	# Update Left Card
	_populate_card(
		lvl_left,
		card_left_container,
		btn_left,
		bg_left,
		content_left,
		title_left,
		sector_left,
		stars_left,
		stats_left,
		lock_left,
		lbl_level_left
	)
	
	# Update Right Card
	_populate_card(
		lvl_right,
		card_right_container,
		btn_right,
		bg_right,
		content_right,
		title_right,
		sector_right,
		stars_right,
		stats_right,
		lock_right,
		lbl_level_right
	)

func _populate_card(
	level_id: int,
	container: VBoxContainer,
	btn: Button,
	bg: TextureRect,
	content: VBoxContainer,
	title_lbl: Label,
	sector_lbl: Label,
	stars_lbl: Label,
	stats_lbl: Label,
	lock_icon: TextureRect,
	level_lbl: Label
) -> void:
	if level_id > TOTAL_LEVELS:
		container.visible = false
		return
	container.visible = true
	level_lbl.text = "Level %d" % level_id
	
	var is_unlocked := true
	if SaveManager:
		is_unlocked = SaveManager.is_level_unlocked(level_id)
		
	# Clear old connections
	for conn in btn.pressed.get_connections():
		btn.pressed.disconnect(conn.callable)
		
	var c_data: Dictionary = ChamberDatabaseClass.get_chamber(level_id)
	var c_title: String = c_data.get("title", "CHAMBER %02d" % level_id)
	var sector_id := ChamberDatabaseClass.get_sector_id(level_id)
	var sector_subtitle := ChamberDatabaseClass.get_sector_subtitle(sector_id)
	var par_loops: int = c_data.get("par_loops", 2)
	
	if is_unlocked:
		btn.disabled = false
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
		level_lbl.modulate = Color(1.0, 1.0, 1.0, 1.0)
		content.visible = true
		lock_icon.visible = false
		
		var display_name := c_title
		if ": " in c_title:
			var parts := c_title.split(": ", false, 1)
			display_name = parts[1]
		title_lbl.text = display_name
		sector_lbl.text = "CHAMBER %02d  •  %s" % [level_id, sector_subtitle]
		
		var stars := 0
		var best_loops := 0
		var best_time := 0.0
		if SaveManager:
			stars = SaveManager.get_level_stars(level_id)
			best_loops = SaveManager.get_best_loops(level_id)
			best_time = SaveManager.get_best_time(level_id)
			
		var star_str := ""
		for s in range(stars):
			star_str += "★ "
		for s in range(3 - stars):
			star_str += "☆ "
		stars_lbl.text = star_str.strip_edges()
		
		if best_loops > 0:
			stats_lbl.text = "PAR: %d  |  RECORD: %d LOOPS (%.1fs)" % [par_loops, best_loops, best_time]
		else:
			stats_lbl.text = "PAR: %d LOOPS  |  UNCOMPLETED" % par_loops
			
		btn.pressed.connect(func(): _load_level(level_id))
	else:
		btn.disabled = true
		# Match Figma locked card opacity: 0.35
		btn.modulate = Color(1.0, 1.0, 1.0, 0.35)
		level_lbl.modulate = Color(1.0, 1.0, 1.0, 0.35)
		content.visible = false
		lock_icon.visible = true

func _on_prev_pressed() -> void:
	if current_slide > 1:
		current_slide -= 1
		SoundManager.play_sfx("click")
		_update_view()

func _on_next_pressed() -> void:
	if current_slide < TOTAL_SLIDES:
		current_slide += 1
		SoundManager.play_sfx("click")
		_update_view()

func _load_level(idx: int) -> void:
	SoundManager.play_sfx("click")
	GameManager.load_level(idx)

func _on_back_pressed() -> void:
	SoundManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_help_pressed() -> void:
	SoundManager.play_sfx("click")
	if guide_modal:
		guide_modal.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if guide_modal and guide_modal.visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
			guide_modal.visible = false
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_on_prev_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_on_next_pressed()
		get_viewport().set_input_as_handled()
