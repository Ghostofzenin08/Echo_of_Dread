class_name Level03
extends BaseLevel

@onready var timed_btn_1: TimedButton = $TimedButton1
@onready var timed_btn_2: TimedButton = $TimedButton2
@onready var laser_1: LaserBarrier = $LaserBarrier1
@onready var laser_2: LaserBarrier = $LaserBarrier2
@onready var alcove_plate: PressurePlate = $AlcovePlate
@onready var wire_1: CircuitWire = $Wire1
@onready var wire_2: CircuitWire = $Wire2

func _ready() -> void:
	chamber_title = "CHAMBER 03: THE VAULT & CAPACITORS"
	level_number = 3
	super._ready()
	
	if timed_btn_1:
		timed_btn_1.state_changed.connect(_on_circuit_1_changed)
	if alcove_plate:
		alcove_plate.state_changed.connect(_on_circuit_1_changed)
	if timed_btn_2:
		timed_btn_2.state_changed.connect(_on_btn2_changed)
		
	if wire_1 and timed_btn_1 and laser_1:
		wire_1.wire_points = PackedVector2Array([
			timed_btn_1.position,
			Vector2(410, timed_btn_1.position.y),
			Vector2(410, laser_1.position.y),
			laser_1.position
		])
		
	if wire_2 and timed_btn_2 and laser_2:
		wire_2.wire_points = PackedVector2Array([
			timed_btn_2.position,
			Vector2(760, timed_btn_2.position.y),
			Vector2(760, laser_2.position.y),
			laser_2.position
		])

func _on_circuit_1_changed(_val: Variant = null) -> void:
	var btn_active: bool = timed_btn_1 != null and timed_btn_1.is_active
	var plate_active: bool = alcove_plate != null and alcove_plate.is_pressed
	var powered: bool = btn_active or plate_active
	if laser_1:
		laser_1.set_active(not powered)
	if wire_1:
		wire_1.set_powered(powered)

func _on_btn2_changed(is_active: bool) -> void:
	if laser_2:
		laser_2.set_active(not is_active)
	if wire_2:
		wire_2.set_powered(is_active)
