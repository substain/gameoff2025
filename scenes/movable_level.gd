class_name MovableLevel
extends Node2D

@export var move_speed: float = 50
 
var is_running: bool = false

func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	if !is_running:
		return
		
	global_position.x = global_position.x - delta * move_speed

func start() -> void:
	is_running = true
	
func stop() -> void:
	is_running = false

func reset() -> void:
	global_position.x = 0
