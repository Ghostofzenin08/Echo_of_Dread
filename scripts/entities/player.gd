class_name Player
extends CharacterBody2D

signal interaction_performed(target: Node2D)

@export var move_speed: float = 200.0
@export var acceleration: float = 1200.0
@export var friction: float = 1400.0

var facing_direction: Vector2 = Vector2.DOWN
var is_interacting: bool = false
var nearby_interactables: Array[Area2D] = []

@onready var interaction_detector: Area2D = $InteractionDetector
@onready var visual_root: Node2D = $VisualRoot

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2 # Layer 2: Player
	collision_mask = 1  # Layer 1: World
	if interaction_detector:
		interaction_detector.area_entered.connect(_on_interactable_entered)
		interaction_detector.area_exited.connect(_on_interactable_exited)

func _physics_process(delta: float) -> void:
	if GameManager.is_paused or GameManager.is_narrative_open:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var input_vector := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()
		
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * move_speed, acceleration * delta)
		facing_direction = input_vector
		if visual_root:
			visual_root.rotation = facing_direction.angle() + PI * 0.5
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
	move_and_slide()
	
	# Check interact key
	is_interacting = Input.is_action_just_pressed("interact")
	if is_interacting:
		_try_interact()

func _try_interact() -> void:
	if nearby_interactables.is_empty():
		return
		
	# Purge invalid or queued-for-deletion areas
	nearby_interactables = nearby_interactables.filter(func(a): return is_instance_valid(a) and not a.is_queued_for_deletion())
	if nearby_interactables.is_empty():
		return
		
	# Pick the closest interactable
	var closest: Area2D = null
	var min_dist := INF
	for area in nearby_interactables:
		var dist := global_position.distance_to(area.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = area
				
	if closest and closest.has_method("interact"):
		closest.interact(self)
		interaction_performed.emit(closest)
	elif closest and closest.get_parent() and is_instance_valid(closest.get_parent()) and closest.get_parent().has_method("interact"):
		closest.get_parent().interact(self)
		interaction_performed.emit(closest.get_parent())

func _on_interactable_entered(area: Area2D) -> void:
	if area.is_in_group("interactable") and not nearby_interactables.has(area):
		nearby_interactables.append(area)

func _on_interactable_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)

func reset_state(spawn_pos: Vector2) -> void:
	global_position = spawn_pos
	velocity = Vector2.ZERO
	facing_direction = Vector2.DOWN
	is_interacting = false
	nearby_interactables.clear()
	if visual_root:
		visual_root.rotation = PI

