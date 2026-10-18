class_name VictoryScreen
extends Control

@onready var replay_btn: Button = $Panel/VBox/ReplayButton
@onready var menu_btn: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if has_node("Panel/VBox/LoreText") and SaveManager:
		var lore_label: RichTextLabel = $Panel/VBox/LoreText
		var stats_str := "\n\n[color=#33e699][b]— RESEARCH PROTOCOL SUMMARY —[/b][/color]\n"
		var total_loops := 0
		var total_time := 0.0
		for lvl in range(1, GameManager.TOTAL_LEVELS + 1):
			var loops := SaveManager.get_best_loops(lvl)
			var time := SaveManager.get_best_time(lvl)
			total_loops += loops
			total_time += time
			stats_str += "[color=#4dd2ff]Chamber %02d:[/color] %d Loops (%04.1fs)   " % [lvl, loops, time]
			if lvl % 2 == 0:
				stats_str += "\n"
		stats_str += "[color=#ffd24d]Total Chronal Loops: %d  |  Cumulative Drift: %04.1fs[/color]" % [total_loops, total_time]
		lore_label.text += stats_str
		
	if replay_btn:
		replay_btn.pressed.connect(func():
			SoundManager.play_sfx("click")
			GameManager.start_game()
		)
	if menu_btn:
		menu_btn.pressed.connect(func():
			SoundManager.play_sfx("click")
			GameManager.return_to_main_menu()
		)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		SoundManager.play_sfx("click")
		GameManager.start_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		SoundManager.play_sfx("click")
		GameManager.return_to_main_menu()
		get_viewport().set_input_as_handled()
