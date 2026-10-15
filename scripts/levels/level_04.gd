class_name Level04
extends BaseLevel

@onready var plate_north: PressurePlate = $PlateNorth
@onready var plate_south: PressurePlate = $PlateSouth
@onready var switch_east: LeverSwitch = $SwitchEast
@onready var plate_master: PressurePlate = $PlateMaster
@onready var core_door: LockedDoor = $CoreDoor
@onready var terminal_final: TerminalLog = $TerminalFinal
@onready var wire_north: CircuitWire = $WireNorth
@onready var wire_south: CircuitWire = $WireSouth
@onready var wire_east: CircuitWire = $WireEast
@onready var wire_master: CircuitWire = $WireMaster

func _ready() -> void:
	chamber_title = "CHAMBER 04: THE RESONANCE CORE"
	level_number = 4
	super._ready()
	
	if core_door:
		core_door.logic_mode = LockedDoor.LogicMode.AND
		if plate_north:
			core_door.register_trigger(plate_north)
			plate_north.state_changed.connect(func(s): if wire_north: wire_north.set_powered(s))
		if plate_south:
			core_door.register_trigger(plate_south)
			plate_south.state_changed.connect(func(s): if wire_south: wire_south.set_powered(s))
		if switch_east:
			core_door.register_trigger(switch_east)
			switch_east.state_changed.connect(func(s): if wire_east: wire_east.set_powered(s))
		if plate_master:
			core_door.register_trigger(plate_master)
			plate_master.state_changed.connect(func(s): if wire_master: wire_master.set_powered(s))
			
	if wire_north and plate_north and core_door:
		wire_north.wire_points = PackedVector2Array([
			plate_north.position,
			Vector2(core_door.position.x - 20, plate_north.position.y),
			core_door.position
		])
	if wire_south and plate_south and core_door:
		wire_south.wire_points = PackedVector2Array([
			plate_south.position,
			Vector2(core_door.position.x - 20, plate_south.position.y),
			core_door.position
		])
	if wire_east and switch_east and core_door:
		wire_east.wire_points = PackedVector2Array([
			switch_east.position,
			Vector2(switch_east.position.x, core_door.position.y - 14),
			core_door.position
		])
	if wire_master and plate_master and core_door:
		wire_master.wire_points = PackedVector2Array([
			plate_master.position,
			Vector2(plate_master.position.x, core_door.position.y + 14),
			core_door.position
		])
