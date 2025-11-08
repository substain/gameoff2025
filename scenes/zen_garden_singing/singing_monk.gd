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

func _ready() -> void:
	stop_moving()
	
func start_moving() -> void:
	anim_player.play(ANIM_IDLE)

func stop_moving() -> void:
	anim_player.stop()

func shoot_note(is_hit: bool) -> void:
	var flying_note: FlyingNote = FLYING_NOTE.instantiate() as FlyingNote
	add_child(flying_note)
	flying_note.position = Vector2.ZERO	
	var targetpos: Vector2 = target_pos_node.get_telegraphed_position(0.0)
	flying_note.start_shoot(targetpos, is_hit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action1"):
		anim_player.play(ANIM_SING)
		is_one_shot_active = true
		anim_timer.start()

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
	
func _on_rhythm_base_note_tap_hit(track: RhythmTrack, note: RhythmNote) -> void:
	if track.name != "MIDI Drums":
		return
	is_one_shot_active = true
	shoot_note(true)

func _on_rhythm_base_started_playing() -> void:
	start_moving()

func _on_rhythm_base_stopped_playing() -> void:
	stop_moving()
