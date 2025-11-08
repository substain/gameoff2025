class_name SingingMonk
extends Node2D

const FLYING_NOTE = preload("uid://ocykk4ntbiep")

const ANIM_IDLE: String = "idle"
const ANIM_SING: String = "sing"
const ANIM_FAIL: String = "fail"

@export var target_pos_node: ZenPlayerPathFollow
@export_category("internal nodes")
@export var anim_player: AnimationPlayer
@export var anim_timer: Timer

var is_one_shot_active: bool = false

func shoot_note(is_hit: bool) -> void:
	var targetpos: Vector2 = target_pos_node.get_telegraphed_position(0.1)
	var flying_note: FlyingNote = FLYING_NOTE.instantiate() as FlyingNote
	add_child(flying_note)
	flying_note.position = Vector2.ZERO	
	flying_note.start_shoot(targetpos, is_hit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action2"):
		is_one_shot_active = false
		anim_player.play(ANIM_SING)
	if event.is_action_released("action2"):
		anim_player.play(ANIM_IDLE)

func on_fail() -> void:
	anim_player.play(ANIM_FAIL)

func _on_timer_timeout() -> void:
	if is_one_shot_active:
		anim_player.play(ANIM_IDLE)

func _on_rhythm_base_note_failed(track: RhythmTrack, note: RhythmNote) -> void:
	if track.name != "MIDI Drums":
		return
	is_one_shot_active = true
	shoot_note(false)
	anim_player.play(ANIM_SING)
	anim_timer.start()

func _on_rhythm_base_note_tap_hit(track: RhythmTrack, note: RhythmNote) -> void:
	if track.name != "MIDI Drums":
		return
	is_one_shot_active = true
	shoot_note(true)
	anim_player.play(ANIM_SING)
	anim_timer.start()
