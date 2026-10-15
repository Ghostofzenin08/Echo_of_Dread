class_name Level01
extends BaseLevel

@onready var plate: PressurePlate = $PressurePlate
@onready var door: LockedDoor = $LockedDoor
@onready var wire: CircuitWire = $CircuitWire

func _ready() -> void:
	chamber_title = "CHAMBER 01: TEMPORAL RESONANCE"
	level_number = 1
	super._ready()
	
	if plate and door:
		door.register_trigger(plate)
		plate.state_changed.connect(_on_plate_state_changed)
		
	if wire and plate and door:
		wire.wire_points = PackedVector2Array([
			plate.position,
			Vector2(plate.position.x, door.position.y),
			door.position
		])

func _on_plate_state_changed(is_pressed: bool) -> void:
	if wire:
		wire.set_powered(is_pressed)
