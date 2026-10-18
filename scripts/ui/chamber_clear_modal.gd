class_name ChamberClearModal
extends Control

# ChamberClearModal: High-dopamine victory modal shown upon securing a Chamber.
# Displays sequential animated 3-star ratings, loop vs par comparisons,
# personal record badges, lore unlocks, and instant navigation (Next / Retry / Sector Map).

signal next_chamber_requested
signal retry_chamber_requested
signal sector_select_requested

@onready var title_label: Label = find_child("TitleLabel", true, false) as Label
@onready var sector_badge: Label = find_child("SectorBadge", true, false) as Label
@onready var star1_label: Label = find_child("Star1", true, false) as Label
@onready var star2_label: Label = find_child("Star2", true, false) as Label
@onready var star3_label: Label = find_child("Star3", true, false) as Label
@onready var rank_label: Label = find_child("RankLabel", true, false) as Label

@onready var loop_summary: Label = find_child("LoopSummary", true, false) as Label
@onready var time_summary: Label = find_child("TimeSummary", true, false) as Label
@onready var record_badge: Label = find_child("RecordBadge", true, false) as Label
@onready var lore_badge: Label = find_child("LoreBadge", true, false) as Label
@onready var total_stars_label: Label = find_child("TotalStarsLabel", true, false) as Label

@onready var next_button: Button = find_child("NextButton", true, false) as Button
@onready var retry_button: Button = find_child("RetryButton", true, false) as Button
@onready var select_button: Button = find_child("SelectButton", true, false) as Button

var current_chamber_idx: int = 1
var earned_stars: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bind_buttons()
	visible = false

func _bind_buttons() -> void:
	if next_button and not next_button.pressed.is_connected(_on_next_pressed):
		next_button.pressed.connect(_on_next_pressed)
	if retry_button and not retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.connect(_on_retry_pressed)
	if select_button and not select_button.pressed.is_connected(_on_select_pressed):
		select_button.pressed.connect(_on_select_pressed)

func display_results(chamber_num: int, loop_count: int, time_sec: float, par_loops: int, is_new_record: bool = false, lore_log_id: String = "") -> void:
	current_chamber_idx = chamber_num
	
	if loop_count <= par_loops:
		earned_stars = 3
	elif loop_count <= par_loops + 1:
		earned_stars = 2
	else:
		earned_stars = 1
		
	var sector_idx := int(ceili(float(chamber_num) / 10.0))
	var sector_names := {
		1: "SECTOR 1: ALPHA WING",
		2: "SECTOR 2: BETA WING",
		3: "SECTOR 3: GAMMA WING",
		4: "SECTOR 4: DELTA WING",
		5: "SECTOR 5: OMEGA WING"
	}
	
	if title_label:
		title_label.text = "CHAMBER %02d SECURED" % chamber_num
	if sector_badge:
		sector_badge.text = sector_names.get(sector_idx, "RESEARCH FACILITY")
		
	if loop_summary:
		loop_summary.text = "LOOPS: %d  (PAR: %d)" % [loop_count, par_loops]
	if time_summary:
		time_summary.text = "DRIFT: %04.1fs" % time_sec
		
	if record_badge:
		record_badge.visible = is_new_record
		
	if lore_badge:
		if not lore_log_id.is_empty():
			lore_badge.visible = true
			lore_badge.text = "[ TRANSMISSION %s DECODED ]" % lore_log_id.to_upper()
		else:
			lore_badge.visible = false
			
	var total_stars := 0
	if SaveManager:
		total_stars = SaveManager.get_total_stars()
	if total_stars_label:
		total_stars_label.text = "TOTAL CHRONAL STARS: %d / 150" % total_stars
		
	if next_button:
		if chamber_num >= 50:
			next_button.text = "CONFRONT CORE [ENTER]"
		else:
			next_button.text = "NEXT CHAMBER [ENTER]"
			
	visible = true
	_animate_stars_sequence()

func _animate_stars_sequence() -> void:
	# Reset stars
	if star1_label: star1_label.text = "☆"
	if star2_label: star2_label.text = "☆"
	if star3_label: star3_label.text = "☆"
	if rank_label: rank_label.text = "CALCULATING TEMPORAL EFFICIENCY..."
	
	# Sequentially pop in stars
	var tween := create_tween()
	
	# Star 1
	tween.tween_callback(func():
		if star1_label:
			star1_label.text = "★"
			star1_label.modulate = Color(1.0, 0.85, 0.25)
		SoundManager.play_sfx("star_ding", 1.0)
	)
	tween.tween_interval(0.28)
	
	# Star 2
	if earned_stars >= 2:
		tween.tween_callback(func():
			if star2_label:
				star2_label.text = "★"
				star2_label.modulate = Color(1.0, 0.85, 0.25)
			SoundManager.play_sfx("star_ding", 1.2)
		)
		tween.tween_interval(0.28)
		
	# Star 3
	if earned_stars >= 3:
		tween.tween_callback(func():
			if star3_label:
				star3_label.text = "★"
				star3_label.modulate = Color(1.0, 0.9, 0.3)
			SoundManager.play_sfx("star_3_fanfare", 1.0)
		)
		tween.tween_interval(0.2)
		
	# Rank reveal
	tween.tween_callback(func():
		if rank_label:
			match earned_stars:
				3:
					rank_label.text = "★ ★ ★  CHRONAL TRANSCENDENCE"
					rank_label.modulate = Color(1.0, 0.88, 0.25)
				2:
					rank_label.text = "★ ★ ☆  TEMPORAL RESONANCE"
					rank_label.modulate = Color(0.3, 0.9, 1.0)
				_:
					rank_label.text = "★ ☆ ☆  PARADOX SURVIVOR"
					rank_label.modulate = Color(0.7, 0.8, 0.9)
	)

func _on_next_pressed() -> void:
	SoundManager.play_sfx("click")
	visible = false
	next_chamber_requested.emit()

func _on_retry_pressed() -> void:
	SoundManager.play_sfx("click")
	visible = false
	retry_chamber_requested.emit()

func _on_select_pressed() -> void:
	SoundManager.play_sfx("click")
	visible = false
	sector_select_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_on_next_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("reset_loop"):
		_on_retry_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		_on_select_pressed()
		get_viewport().set_input_as_handled()
