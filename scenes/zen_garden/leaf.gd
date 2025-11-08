class_name Leaf
extends Node2D

signal on_remove

const LEAF_FALL_ANIM: String = "fall"
const LEAF_IDLE_ANIM: String = "idle"
const SHADOW_FAR_ANIM: String = "far"
const SHADOW_MEDIUM_ANIM: String = "medium"
const SHADOW_NEAR_ANIM: String = "near"

@export var height_offset: float = 100.0
@export var hit_height_offset: float = 8.0
@export var speed: float = 50.0

@export_category("internal nodes")
@export var leaf_object: Node2D
@export var leaf_sprite: Sprite2D
@export var shadow_object: Node2D
@export var leaf_anim_player: AnimationPlayer
@export var shadow_anim_player: AnimationPlayer

var is_falling: bool = false
var fall_time: float = 0.5
var is_finished: bool = false

func _ready() -> void:
	leaf_sprite.flip_h = randf() > 0.5
	leaf_anim_player.play(LEAF_IDLE_ANIM)
	shadow_object.visible = false
	leaf_object.visible = false
	shadow_anim_player.play(SHADOW_FAR_ANIM)

func _process(delta: float) -> void:
	if is_finished || !is_falling:
		return

	leaf_object.global_position += Vector2(0.0, speed * delta)
	#leaf_anim_player.play(LEAF_FALL_ANIM)
	
	var relative_pos: float = (global_position.y - leaf_object.global_position.y) / (height_offset+hit_height_offset)
	if relative_pos > 0.66:
		shadow_anim_player.play(SHADOW_FAR_ANIM)
	elif relative_pos > 0.33:
		shadow_anim_player.play(SHADOW_MEDIUM_ANIM)
	else:
		shadow_anim_player.play(SHADOW_NEAR_ANIM)

	if relative_pos <= 0:
		land()
		
func set_fall_time(fall_time_new: float, adapt_height: bool = false) -> void:
	fall_time = fall_time_new
	if !adapt_height:
		speed = height_offset / fall_time_new
	else:
		height_offset = fall_time_new * speed

func start_falling() -> void:
	leaf_object.global_position.y = global_position.y - (height_offset+hit_height_offset)
	shadow_anim_player.play(SHADOW_FAR_ANIM)
	leaf_anim_player.play(LEAF_FALL_ANIM)
	shadow_object.visible = true
	leaf_object.visible = true
	is_falling = true
	await get_tree().create_timer(fall_time).timeout
	var relative_pos: float = (global_position.y - leaf_object.global_position.y) / height_offset

func land() -> void:
	if is_finished:
		push_warning("leaf already finished, but 'land()' was called")
		return
	is_finished = true

	is_falling = false
	leaf_anim_player.play(LEAF_IDLE_ANIM)
	on_remove.emit()
	var despawn_tween: Tween = create_tween()
	despawn_tween.tween_property(self, "modulate:a", 0.0, 4.0)
	await despawn_tween.finished
	queue_free()
	
func get_hit(from_dir: Vector2) -> void:
	if is_finished:
		push_warning("leaf already finished, but 'get_hit()' was called")
		return
	is_finished = true
	is_falling = false
	var push_strength: float = randf_range(50.0, 400.0)
	var push_angle: float = from_dir.angle() + randf_range(-PI/3, PI/3)
	var push_dir: Vector2 = Vector2.from_angle(push_angle) * push_strength
	
	on_remove.emit()
	shadow_object.queue_free()
	var despawn_tween: Tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	despawn_tween.tween_method(rotate, 1.0, 0.0, 0.5)
	despawn_tween.tween_property(self, "global_position", global_position + push_dir, 1.0)
	despawn_tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await despawn_tween.finished

	queue_free()
