class_name Level02
extends BaseLevel

@onready var plate_a: PressurePlate = $PlateAlpha
@onready var plate_b: PressurePlate = $PlateBeta
@onready var door: LockedDoor = $LockedDoor
@onready var wire_a: CircuitWire = $WireAlpha
@onready var wire_b: CircuitWire = $WireBeta
@onready var bypass_lever: LeverSwitch = $BypassLever

func _ready() -> void:
	chamber_title = "CHAMBER 02: SYNCHRONIZED ISOLATION"
	level_number = 2
	super._ready()
	
	if door:
		door.logic_mode = LockedDoor.LogicMode.AND
		if plate_a:
			door.register_trigger(plate_a)
		if plate_b:
			door.register_trigger(plate_b)
			
	if plate_a:
		plate_a.state_changed.connect(_on_circuit_a_input_changed)
	if bypass_lever:
		bypass_lever.state_changed.connect(_on_circuit_a_input_changed)
	if plate_b:
		plate_b.state_changed.connect(_on_plate_b_changed)
			
	if wire_a and plate_a and door:
		wire_a.wire_points = PackedVector2Array([
			plate_a.position,
			Vector2(door.position.x - 30, plate_a.position.y),
			Vector2(door.position.x - 30, door.position.y - 12),
			door.position
		])
		
	if wire_b and plate_b and door:
		wire_b.wire_points = PackedVector2Array([
			plate_b.position,
			Vector2(door.position.x - 30, plate_b.position.y),
			Vector2(door.position.x - 30, door.position.y + 12),
			door.position
		])

func _on_circuit_a_input_changed(_val: Variant = null) -> void:
	var is_a_active: bool = (plate_a != null and plate_a.is_pressed) or (bypass_lever != null and bypass_lever.is_active)
	if door and plate_a:
		door.set_trigger_state(plate_a, is_a_active)
	if wire_a:
		wire_a.set_powered(is_a_active)

func _on_plate_b_changed(is_pressed: bool) -> void:
	if wire_b:
		wire_b.set_powered(is_pressed)
