class_name Player
extends CharacterBody2D

signal player_died

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var start_position: Vector2
var is_running: bool = false

@onready var movement_camera: Camera2D = $MovementCamera
@onready var placement_camera: Camera2D = $"../Placement/PlacementCamera"

func _ready() -> void:
	start_position = global_position

func _physics_process(delta: float) -> void:
	if !is_running:
		return
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func start() -> void:
	is_running = true
	movement_camera.make_current()

func stop() -> void:
	is_running = false
	placement_camera.make_current()
	
func reset() -> void:
	global_position = start_position

func die() -> void:
	player_died.emit()
