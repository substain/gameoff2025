class_name SingingMonk
extends Node2D

const FLYING_NOTE: PackedScene = preload("uid://ocykk4ntbiep")

const ANIM_IDLE: String = "idle"
const ANIM_SING: String = "sing"
const ANIM_FAIL: String = "fail"
const ANIM_RESET: String = "RESET"

@export var exact_hit: bool = true
@export var target_pos_node: ZenPlayerPathFollow
@export var leaf_manager: RhythmEventCreator
@export_category("internal nodes")
@export var anim_player: AnimationPlayer
@export var anim_timer: Timer

var is_one_shot_active: bool = false

var is_moving: bool = false

func _ready() -> void:
	stop_moving()
	
func start_moving() -> void:
	anim_player.play(ANIM_IDLE)
	is_moving = true
	
func stop_moving() -> void:
	anim_player.stop()
	is_moving = false

func shoot_note(is_hit: bool, target_leaf: Leaf = null) -> void:
	var flying_note: FlyingNote = FLYING_NOTE.instantiate() as FlyingNote
	add_child(flying_note)
	flying_note.position = Vector2.ZERO	
	var targetpos: Vector2
	if exact_hit && is_hit && target_leaf != null:
		targetpos = target_leaf.global_position
	else:
		targetpos = target_pos_node.get_telegraphed_position(0.0)
	
	flying_note.start_shoot(targetpos, is_hit, target_leaf)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(InputHandler.ACTION_B):
		anim_player.play(ANIM_SING)
		is_one_shot_active = true
		anim_timer.start()

	if event.is_action_pressed(InputHandler.ACTION_A):
		is_one_shot_active = false
		anim_player.play(ANIM_SING)
	if event.is_action_released(InputHandler.ACTION_A):
		if is_moving:
			anim_player.play(ANIM_IDLE)
		else:
			anim_player.play(ANIM_RESET)
			anim_player.stop()

func on_fail() -> void:
	anim_player.play(ANIM_FAIL)

func _on_timer_timeout() -> void:
	if is_one_shot_active:
		if is_moving:
			anim_player.play(ANIM_IDLE)
		else:
			anim_player.play(ANIM_RESET)
			anim_player.stop()
			
func _on_rhythm_base_note_failed(track: RhythmTrack, _note: RhythmNote) -> void:
	if track.name != "MIDI Drums":
		return
	is_one_shot_active = true
	shoot_note(false)
	
func _on_rhythm_base_note_tap_hit(track: RhythmTrack, note: RhythmNote, _diff: float) -> void:
	if track.name != "MIDI Drums":
		return
	is_one_shot_active = true
	var target_leaf: Leaf = leaf_manager.get_leaf_by_note(note)
	shoot_note(true, target_leaf)
	

func _on_rhythm_base_started_playing() -> void:
	start_moving()

func _on_rhythm_base_stopped_playing() -> void:
	stop_moving()
