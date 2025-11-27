class_name FlyingNote
extends Node2D

const ANIM_SPAWN: String = "spawn"
const ANIM_FLY: String = "fly"
const ANIM_HIT: String = "destroy"

@export var animation_player: AnimationPlayer
@export var speed: float = 1400

var is_flying: bool = false
var direction: Vector2
var is_hit: bool
var target_point: Vector2
var target_falling_object: FallingObject

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	if !is_flying:
		return
	
	global_position = global_position + (direction * speed * delta)	
	
	if is_hit && global_position.distance_to(target_point) < (speed*delta):
		on_hit()		
		

func start_shoot(target_point_new: Vector2, is_hit_new: bool, target_falling_object_new: FallingObject = null) -> void:
	is_flying = true
	is_hit = is_hit_new
	target_point = target_point_new
	target_falling_object = target_falling_object_new
	direction = (target_point_new - global_position).normalized()
	animation_player.play(ANIM_SPAWN)
	await get_tree().create_timer(8.0).timeout
	queue_free()
	
func on_hit() -> void:
	if is_hit && target_falling_object != null:
		target_falling_object.get_hit(direction)
	animation_player.play(ANIM_HIT)
	is_flying = false

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == ANIM_HIT:
		queue_free()

	if anim_name == ANIM_SPAWN:
		animation_player.play(ANIM_FLY)
		
