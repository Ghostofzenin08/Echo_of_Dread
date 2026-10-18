class_name ChamberRunner
extends BaseLevel

# ChamberRunner: Universal dynamic loader for all 50 Chambers defined in ChamberDatabase.
# Reads chamber geometry, obstacles, triggers, doors, lasers, drones, wires, and lore terminals,
# instantiating them dynamically while maintaining full BaseLevel camera/shader/HUD integration.

const PlateScene = preload("res://scenes/interactables/pressure_plate.tscn")
const SwitchScene = preload("res://scenes/interactables/lever_switch.tscn")
const ButtonScene = preload("res://scenes/interactables/timed_button.tscn")
const DoorScene = preload("res://scenes/interactables/locked_door.tscn")
const LaserScene = preload("res://scenes/interactables/laser_barrier.tscn")
const DroneScene = preload("res://scenes/entities/security_drone.tscn")
const TerminalScene = preload("res://scenes/interactables/terminal_log.tscn")
const WireScene = preload("res://scenes/interactables/circuit_wire.tscn")
const ExitScene = preload("res://scenes/interactables/level_exit.tscn")
const ChamberDatabaseClass = preload("res://scripts/world/chamber_database.gd")

@onready var room_builder: RoomBuilder = $RoomBuilder
@onready var level_exit: LevelExit = get_node_or_null("LevelExit")

var _triggers_by_id: Dictionary = {}
var _doors_by_id: Dictionary = {}
var _lasers_by_id: Dictionary = {}

@export var level_number_override: int = 0

func _ready() -> void:
	if level_number_override > 0:
		level_number = level_number_override
	elif GameManager and GameManager.current_level_index > 0:
		level_number = GameManager.current_level_index
		
	var data: Dictionary = ChamberDatabaseClass.get_chamber(level_number)
	chamber_title = data.get("title", "CHAMBER %02d" % level_number)
	
	_build_chamber(data)
	super._ready()

func _build_chamber(data: Dictionary) -> void:
	# 1. Setup RoomBuilder
	if not room_builder:
		room_builder = get_node_or_null("RoomBuilder") as RoomBuilder
		if not room_builder:
			room_builder = RoomBuilder.new()
			room_builder.name = "RoomBuilder"
			add_child(room_builder)
			
	var r_size: Vector2 = data.get("room_size", Vector2(1280, 720))
	var walls_raw: Array = data.get("interior_walls", [])
	var walls: Array[Rect2] = []
	for w in walls_raw:
		if w is Rect2:
			walls.append(w)
	room_builder.interior_walls = walls
	
	# 2. Setup Spawns & Exit
	var spawn_pos: Vector2 = data.get("spawn_pos", Vector2(160, 360))
	if spawn_point:
		spawn_point.position = spawn_pos
	if player:
		player.position = spawn_pos
		
	var exit_pos: Vector2 = data.get("exit_pos", Vector2(1120, 360))
	if not level_exit:
		level_exit = get_node_or_null("LevelExit") as LevelExit
		if not level_exit and ExitScene:
			level_exit = ExitScene.instantiate() as LevelExit
			level_exit.name = "LevelExit"
			add_child(level_exit)
	if level_exit:
		level_exit.position = exit_pos
		
	# 3. Instantiate Doors
	for d in data.get("doors", []):
		var door: LockedDoor = DoorScene.instantiate() as LockedDoor
		door.name = str(d.get("id", "door"))
		door.position = d.get("pos", Vector2.ZERO)
		door.rotation = d.get("rot", 0.0)
		var logic_str: String = d.get("logic", "AND")
		door.logic_mode = LockedDoor.LogicMode.OR if logic_str == "OR" else LockedDoor.LogicMode.AND
		add_child(door)
		_doors_by_id[d.get("id", "")] = door

	# 4. Instantiate Lasers
	for l in data.get("lasers", []):
		var laser: LaserBarrier = LaserScene.instantiate() as LaserBarrier
		laser.name = str(l.get("id", "laser"))
		laser.position = l.get("pos", Vector2.ZERO)
		laser.barrier_length = l.get("length", 96.0)
		if l.get("orientation", "horizontal") == "vertical":
			laser.rotation = PI * 0.5
		add_child(laser)
		_lasers_by_id[l.get("id", "")] = laser

	# 5. Instantiate Pressure Plates
	for p in data.get("plates", []):
		var plate: PressurePlate = PlateScene.instantiate() as PressurePlate
		plate.name = str(p.get("id", "plate"))
		plate.position = p.get("pos", Vector2.ZERO)
		add_child(plate)
		_triggers_by_id[p.get("id", "")] = plate
		_route_trigger_target(plate, p.get("target", ""))

	# 6. Instantiate Toggle Switches
	for s in data.get("switches", []):
		var sw: LeverSwitch = SwitchScene.instantiate() as LeverSwitch
		sw.name = str(s.get("id", "switch"))
		sw.position = s.get("pos", Vector2.ZERO)
		add_child(sw)
		_triggers_by_id[s.get("id", "")] = sw
		_route_trigger_target(sw, s.get("target", ""))

	# 7. Instantiate Timed Buttons
	for b in data.get("timed_buttons", []):
		var btn: TimedButton = ButtonScene.instantiate() as TimedButton
		btn.name = str(b.get("id", "timed_button"))
		btn.position = b.get("pos", Vector2.ZERO)
		btn.active_duration = b.get("duration", 5.0)
		add_child(btn)
		_triggers_by_id[b.get("id", "")] = btn
		_route_trigger_target(btn, b.get("target", ""))

	# 8. Instantiate Security Drones
	for dr in data.get("drones", []):
		var drone: CharacterBody2D = DroneScene.instantiate() as CharacterBody2D
		drone.position = dr.get("pos", Vector2.ZERO)
		if "waypoint_offsets" in drone:
			drone.waypoint_offsets = dr.get("waypoints", PackedVector2Array([Vector2.ZERO]))
		if "patrol_speed" in drone:
			drone.patrol_speed = dr.get("patrol_speed", 75.0)
		if "chase_speed" in drone and dr.has("chase_speed"):
			drone.chase_speed = dr.get("chase_speed", 140.0)
		add_child(drone)

	# 9. Instantiate Narrative Terminals
	for t in data.get("terminals", []):
		var term: TerminalLog = TerminalScene.instantiate() as TerminalLog
		term.position = t.get("pos", Vector2.ZERO)
		term.log_id = t.get("log_id", "log_01")
		add_child(term)

	# 10. Instantiate Circuit Wires
	for w in data.get("wires", []):
		var wire: CircuitWire = WireScene.instantiate() as CircuitWire
		var pts: PackedVector2Array = []
		if w.has("points"):
			pts = w.get("points")
		elif w.has("from") and w.has("to"):
			var p_from: Vector2 = w.get("from")
			var p_to: Vector2 = w.get("to")
			pts = PackedVector2Array([p_from, Vector2(p_from.x, p_to.y), p_to])
		wire.wire_points = pts
		add_child(wire)
		
		var trig_id: String = w.get("trigger_id", "")
		if _triggers_by_id.has(trig_id):
			var trig: Node = _triggers_by_id[trig_id]
			if trig.has_signal("state_changed"):
				trig.state_changed.connect(wire.set_powered)

func _route_trigger_target(trigger_node: Node, target_id: String) -> void:
	if target_id.is_empty():
		return
	if _doors_by_id.has(target_id):
		var door: LockedDoor = _doors_by_id[target_id]
		door.register_trigger(trigger_node)
	elif _lasers_by_id.has(target_id):
		var laser: LaserBarrier = _lasers_by_id[target_id]
		if trigger_node.has_signal("state_changed"):
			trigger_node.state_changed.connect(laser._on_trigger_state_changed)
