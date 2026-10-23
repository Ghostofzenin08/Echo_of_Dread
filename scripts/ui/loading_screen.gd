class_name LoadingScreen
extends CanvasLayer

# LoadingScreen: High-tech loading transition system for Echo of Dread.
# Handles Figma-spec loading designs:
# - Web Desktop Level Changes (Node 244:157): Chamber preview + bottom-left spinner + "Initializing"
# - Web Desktop Game Starting (Node 244:409): Pure cinematic center spinning quantum shard
# - Mobile All Starting & Levels (Node 244:367): Rounded mobile center spinning quantum shard

enum LoaderType {
	WEB_DESKTOP_LEVELS,
	WEB_DESKTOP_START,
	MOBILE_ALL
}

signal loading_started
signal loading_completed

@onready var root: Control = $Root
@onready var web_levels_view: Control = $Root/WebLevelsView
@onready var web_start_view: Control = $Root/WebStartView
@onready var mobile_view: Control = $Root/MobileView

@onready var spinner_levels: TextureRect = $Root/WebLevelsView/BottomRow/SpinnerContainer/ShardSpinner
@onready var spinner_start: TextureRect = $Root/WebStartView/CenterSpinnerContainer/ShardSpinner
@onready var spinner_mobile: TextureRect = $Root/MobileView/CenterSpinnerContainer/ShardSpinner

var _active_spinner: TextureRect = null
var _is_animating: bool = false
var _anim_time: float = 0.0

const SPIN_SPEED: float = 4.2 # Radians per second (~0.67 rev/sec)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if root:
		root.visible = false
		root.modulate = Color(1, 1, 1, 0)

func _process(delta: float) -> void:
	if not _is_animating or not is_instance_valid(_active_spinner):
		return
	_anim_time += delta
	# Smart spinning animation: smooth continuous rotation with subtle quantum scale breathing
	_active_spinner.rotation += SPIN_SPEED * delta
	var pulse := 1.0 + 0.06 * sin(_anim_time * 5.0)
	_active_spinner.scale = Vector2(pulse, pulse)

func start_transition(loader_type: LoaderType, on_swap_scene: Callable, min_duration: float = 0.45) -> void:
	if not root:
		if on_swap_scene.is_valid():
			on_swap_scene.call()
		return

	# Show root
	root.visible = true
	root.modulate = Color(1, 1, 1, 0)
	
	# Select view
	if web_levels_view:
		web_levels_view.visible = (loader_type == LoaderType.WEB_DESKTOP_LEVELS)
	if web_start_view:
		web_start_view.visible = (loader_type == LoaderType.WEB_DESKTOP_START)
	if mobile_view:
		mobile_view.visible = (loader_type == LoaderType.MOBILE_ALL)
		
	match loader_type:
		LoaderType.WEB_DESKTOP_LEVELS:
			_active_spinner = spinner_levels
		LoaderType.WEB_DESKTOP_START:
			_active_spinner = spinner_start
		LoaderType.MOBILE_ALL:
			_active_spinner = spinner_mobile
			
	if _active_spinner:
		_active_spinner.rotation = 0.0
		_active_spinner.scale = Vector2.ONE
	_anim_time = 0.0
	_is_animating = true
	loading_started.emit()
	
	# Fade in
	var tw_in := create_tween()
	tw_in.tween_property(root, "modulate", Color.WHITE, 0.16)
	await tw_in.finished
	
	# Execute scene swap callback while loader is fully opaque
	if on_swap_scene.is_valid():
		on_swap_scene.call()
		
	# Brief polished hold so player sees transition
	await get_tree().create_timer(min_duration, true, false, true).timeout
	
	# Fade out
	var tw_out := create_tween()
	tw_out.tween_property(root, "modulate", Color(1, 1, 1, 0), 0.22)
	await tw_out.finished
	
	_is_animating = false
	root.visible = false
	loading_completed.emit()
