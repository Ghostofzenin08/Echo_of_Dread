class_name TouchControls
extends CanvasLayer

# TouchControls: Responsive on-screen mobile interface for Android / iOS / Web touchscreens.
# Features an analog VirtualJoystick for movement and futuristic touch buttons for
# Interaction ('E'), Loop Rewind ('R'), Echo Purge ('C'), and Pause ('ESC').

const MobileVirtualJoystickClass = preload("res://scripts/ui/virtual_joystick.gd")

@onready var root_control: Control = $RootControl
@onready var joystick_container: Control = $RootControl/BottomLeft/Joystick
@onready var interact_btn: Button = $RootControl/BottomRight/VBox/MainRow/InteractBtn
@onready var loop_btn: Button = $RootControl/BottomRight/VBox/MainRow/LoopBtn
@onready var clear_btn: Button = $RootControl/BottomRight/VBox/AuxRow/ClearBtn
@onready var pause_btn: Button = $RootControl/TopRight/PauseBtn

var _is_enabled: bool = false

func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_connect_buttons()
	_update_visibility_from_settings()
	
	if SaveManager and not SaveManager.settings_changed.is_connected(_update_visibility_from_settings):
		SaveManager.settings_changed.connect(_update_visibility_from_settings)
		
	if GameManager:
		if not GameManager.narrative_opened.is_connected(_on_narrative_opened):
			GameManager.narrative_opened.connect(_on_narrative_opened)
		if not GameManager.narrative_closed.is_connected(_on_narrative_closed):
			GameManager.narrative_closed.connect(_on_narrative_closed)

func _connect_buttons() -> void:
	if interact_btn:
		interact_btn.button_down.connect(func(): Input.action_press("interact"))
		interact_btn.button_up.connect(func(): Input.action_release("interact"))
		
	if loop_btn:
		loop_btn.button_down.connect(func(): Input.action_press("reset_loop"))
		loop_btn.button_up.connect(func(): Input.action_release("reset_loop"))
		
	if clear_btn:
		clear_btn.button_down.connect(func(): Input.action_press("clear_echoes"))
		clear_btn.button_up.connect(func(): Input.action_release("clear_echoes"))
		
	if pause_btn:
		pause_btn.pressed.connect(_on_pause_pressed)

func _on_pause_pressed() -> void:
	var ev_press := InputEventAction.new()
	ev_press.action = "pause"
	ev_press.pressed = true
	Input.parse_input_event(ev_press)
	
	var ev_release := InputEventAction.new()
	ev_release.action = "pause"
	ev_release.pressed = false
	Input.parse_input_event(ev_release)

func _update_visibility_from_settings() -> void:
	if SaveManager:
		_is_enabled = bool(SaveManager.get_setting("touch_controls", false))
	else:
		_is_enabled = OS.has_feature("mobile") or OS.has_feature("touchscreen")
		
	_sync_visibility()

func _sync_visibility() -> void:
	if not root_control:
		return
	if GameManager and (GameManager.is_narrative_open or GameManager.is_paused):
		root_control.visible = false
	else:
		root_control.visible = _is_enabled

func _on_narrative_opened(_data: Dictionary) -> void:
	_sync_visibility()

func _on_narrative_closed() -> void:
	_sync_visibility()

func set_touch_enabled(enabled: bool) -> void:
	_is_enabled = enabled
	if SaveManager:
		SaveManager.set_setting("touch_controls", enabled)
	_sync_visibility()

func is_touch_active() -> bool:
	return _is_enabled and root_control != null and root_control.visible
