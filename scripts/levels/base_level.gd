class_name BaseLevel
extends Node2D

# BaseLevel: Base architecture for all puzzle chambers in Echo Rooms.
# Integrates TactileCamera with procedural screen shake, full-screen temporal
# rewind & time-dilation shader post-processing, and multi-track HUD timeline synchronization.

@export var chamber_title: String = "CHAMBER 01: TEMPORAL RESONANCE"
@export var level_number: int = 1

@onready var loop_manager: LoopManager = $LoopManager
@onready var player: Player = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var game_hud: GameHUD = $GameHUD

const TactileCameraClass = preload("res://scripts/camera/tactile_camera.gd")

var camera: Camera2D = null
var post_process_layer: CanvasLayer = null
var _shader_material: ShaderMaterial = null
var _shader_rect: ColorRect = null
var _rewind_tween: Tween = null

func _ready() -> void:
	if not spawn_point:
		spawn_point = Marker2D.new()
		spawn_point.name = "SpawnPoint"
		spawn_point.position = Vector2(160, 360)
		add_child(spawn_point)
		
	_setup_tactile_camera()
	_setup_post_processing()
	_setup_touch_controls()
	_connect_interactable_trauma()
		
	if game_hud:
		game_hud.set_chamber_title(chamber_title)
		if game_hud.has_method("set_level_number"):
			game_hud.set_level_number(level_number)
		elif game_hud.has_method("set_rewind_available"):
			game_hud.set_rewind_available(level_number > 10 and (SaveManager == null or SaveManager.is_rewind_unlocked()))
		
	if loop_manager and player:
		loop_manager.level_number = level_number
		if not loop_manager.rewind_blocked.is_connected(_on_rewind_blocked):
			loop_manager.rewind_blocked.connect(_on_rewind_blocked)
		if loop_manager.has_signal("loop_duration_changed") and not loop_manager.loop_duration_changed.is_connected(_on_loop_duration_changed):
			loop_manager.loop_duration_changed.connect(_on_loop_duration_changed)
		loop_manager.time_updated.connect(_on_time_updated)
		loop_manager.loop_reset.connect(_on_loop_reset)
		loop_manager.echo_count_changed.connect(_on_echo_count_changed)
		loop_manager.timeline_tracks_updated.connect(_on_timeline_tracks_updated)
		loop_manager.initialize(player, spawn_point.global_position)
		
	SoundManager.play_ambient_drone()

func _exit_tree() -> void:
	SoundManager.stop_ambient_drone()

func _setup_tactile_camera() -> void:
	camera = get_node_or_null("TactileCamera") as Camera2D
	if camera == null:
		camera = TactileCameraClass.new()
		camera.name = "TactileCamera"
		add_child(camera)
		
	var room_builder = get_node_or_null("RoomBuilder")
	if room_builder and "room_size" in room_builder and camera.has_method("set_room_bounds"):
		camera.set_room_bounds(Rect2(Vector2.ZERO, room_builder.room_size))
		
	if player and camera.has_method("set_target"):
		camera.set_target(player)

func _setup_post_processing() -> void:
	post_process_layer = get_node_or_null("PostProcessLayer") as CanvasLayer
	if post_process_layer == null:
		post_process_layer = CanvasLayer.new()
		post_process_layer.name = "PostProcessLayer"
		post_process_layer.layer = 10
		add_child(post_process_layer)
		
		_shader_rect = ColorRect.new()
		_shader_rect.name = "RewindShaderRect"
		_shader_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_shader_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_shader_rect.visible = false
		
		var shader := load("res://shaders/temporal_rewind.gdshader") as Shader
		if shader:
			_shader_material = ShaderMaterial.new()
			_shader_material.shader = shader
			_shader_material.set_shader_parameter("intensity", 0.0)
			_shader_rect.material = _shader_material
			
		post_process_layer.add_child(_shader_rect)

func _setup_touch_controls() -> void:
	var touch_inst := get_node_or_null("TouchControls") as TouchControls
	if touch_inst == null:
		var touch_scene := load("res://scenes/ui/touch_controls.tscn") as PackedScene
		if touch_scene:
			touch_inst = touch_scene.instantiate() as TouchControls
			touch_inst.name = "TouchControls"
			add_child(touch_inst)
	if touch_inst and touch_inst.has_method("set_rewind_unlocked"):
		var can_rewind := level_number > 10 and (SaveManager == null or SaveManager.is_rewind_unlocked())
		touch_inst.set_rewind_unlocked(can_rewind)

func _on_rewind_blocked(reason: String) -> void:
	if game_hud and game_hud.has_method("show_rewind_locked_notice"):
		game_hud.show_rewind_locked_notice(reason)
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.12)

func _connect_interactable_trauma() -> void:
	for child in find_children("*", "", true, false):
		if child is LockedDoor:
			child.door_state_changed.connect(func(is_open: bool):
				if camera:
					camera.add_trauma(0.35 if not is_open else 0.2)
			)
		elif child is LaserBarrier:
			child.laser_state_changed.connect(func(is_active: bool):
				if camera and is_active:
					camera.add_trauma(0.25)
			)
		elif child.is_in_group("enemies"):
			if child.has_signal("player_caught_target") and not child.player_caught_target.is_connected(_on_drone_caught_player):
				child.player_caught_target.connect(_on_drone_caught_player)

func _on_drone_caught_player(_drone: Node, _target: Node) -> void:
	if game_hud and game_hud.has_method("trigger_interception_flash"):
		game_hud.trigger_interception_flash()
	if loop_manager:
		loop_manager.reset_loop()

func trigger_temporal_rewind_fx(duration: float = 0.55) -> void:
	var use_crt := true
	if SaveManager:
		use_crt = SaveManager.get_setting("crt_shader", true)
		
	if _shader_material and _shader_rect and use_crt:
		_shader_rect.visible = true
		if _rewind_tween and _rewind_tween.is_valid():
			_rewind_tween.kill()
		_rewind_tween = create_tween()
		_rewind_tween.tween_method(func(val: float):
			_shader_material.set_shader_parameter("intensity", val)
		, 0.0, 1.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_rewind_tween.tween_method(func(val: float):
			_shader_material.set_shader_parameter("intensity", val)
		, 1.0, 0.0, maxf(0.1, duration - 0.08)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		_rewind_tween.finished.connect(func():
			if _shader_rect:
				_shader_rect.visible = false
			if _shader_material:
				_shader_material.set_shader_parameter("intensity", 0.0)
		)
	else:
		if _shader_rect:
			_shader_rect.visible = false
		if _shader_material:
			_shader_material.set_shader_parameter("intensity", 0.0)
		
	if camera:
		camera.add_trauma(0.65)

func _on_time_updated(current_time: float, max_duration: float) -> void:
	var remaining := maxf(0.0, max_duration - current_time)
	SoundManager.set_urgency(remaining, max_duration)
	if game_hud:
		game_hud.update_time(current_time, max_duration)

func _on_loop_reset(new_loop: int) -> void:
	SoundManager.reset_urgency()
	trigger_temporal_rewind_fx()
	if game_hud:
		game_hud.update_loop_number(new_loop)
		game_hud.trigger_rewind_effect()

func _on_echo_count_changed(count: int) -> void:
	if game_hud and loop_manager:
		game_hud.update_echo_count(count, loop_manager.max_echoes)

func _on_timeline_tracks_updated(tracks: Array) -> void:
	if game_hud:
		game_hud.set_timeline_tracks(tracks)

func _on_loop_duration_changed(_new_dur: float) -> void:
	if game_hud and game_hud.has_method("_update_duration_toggle_ui"):
		game_hud._update_duration_toggle_ui()
