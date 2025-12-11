class_name SingingMonk
extends Node2D

const FLYING_NOTE: PackedScene = preload("uid://ocykk4ntbiep")

const FALLING_OBJECT_TARGET_TRACK: String = "MIDI BELLS"
const HOLD_TRACK: String = "MIDI Throat Singing"

const MIN_POSE_TIME: float = 4.0
const MAX_POSE_TIME: float = 9.0

const ANIM_OPEN_SUFFIX: String = "_open"

enum Anim {
	RESET,
	idle, # and idle_open
	sing, # and sing_open
	happy, # and happy_open
	exhausted, # and exhausted_open
	exhausted_max, # and exhausted_max_open
	
	breath,
	caugh,
	caugh_exhausted,
}

@export var exact_hit: bool = true
@export var target_pos_node: ZenPlayerPathFollow
@export var fall_object_manager: RhythmEventCreator
@export var line_controller: LineController
@export var statue_animation_player: AnimationPlayer

@export_category("internal nodes")
@export var anim_player: AnimationPlayer
@export var anim_timer: Timer
@export var switch_pose_timer: Timer

var current_hold_note_id: String = ""

var is_one_shot_active: bool = false

var is_moving: bool = false
var has_open_pose: bool = false

var mood: float = 0

func _ready() -> void:
	stop_moving()
	
func start_moving() -> void:
	play_anim(Anim.idle)
	start_switch_pose_timer()
	is_moving = true
	
func stop_moving() -> void:
	anim_player.stop()
	switch_pose_timer.stop()
	is_moving = false

func start_telegraph(event: RhythmTriggerEvent) -> void:
	var telegraph_duration: float = -event.offset * 1.2
	var current_length: float = anim_player.get_animation(anim_to_str(Anim.breath)).length
	play_anim(Anim.breath, telegraph_duration/current_length)
	
	
func start_switch_pose_timer() -> void:
	switch_pose_timer.start(randf_range(MIN_POSE_TIME, MAX_POSE_TIME))
		
func shoot_note(is_hit: bool, target_falling_object: FallingObject = null) -> void:
	var flying_note: FlyingNote = FLYING_NOTE.instantiate() as FlyingNote
	add_child(flying_note)
	flying_note.position = Vector2.ZERO	
	var targetpos: Vector2
	if exact_hit && is_hit && target_falling_object != null:
		targetpos = target_falling_object.global_position
	else:
		targetpos = target_pos_node.get_telegraphed_position(0.0)
	
	flying_note.start_shoot(targetpos, is_hit, target_falling_object)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(InputHandler.ACTION_B):
		b_pressed()

	if event.is_action_pressed(InputHandler.ACTION_A):
		a_pressed()
		
	if event.is_action_released(InputHandler.ACTION_A):
		a_released()

func play_anim(anim: Anim, anim_speed: float = 1.0) -> void:
	anim_player.speed_scale = anim_speed
	if has_open_pose && is_switchable_anim(anim):
		anim_player.play(anim_to_str(anim) + ANIM_OPEN_SUFFIX)
	anim_player.play(anim_to_str(anim))

static func get_idle_anim(mood_to_check: float) -> Anim:
	if mood_to_check > -0.4 && mood_to_check < 0.4:
		return Anim.idle

	if mood_to_check > 0.0:
		return Anim.happy
		
	if mood_to_check < -0.8:
		return Anim.exhausted_max
		
	return Anim.exhausted
				
func _on_rhythm_base_note_failed(track: RhythmTrack, _note: RhythmNote) -> void:
	if track.name != HOLD_TRACK && track.name != FALLING_OBJECT_TARGET_TRACK:
		return
	if !current_hold_note_id.is_empty():
		line_controller.stop_hold(current_hold_note_id)
		current_hold_note_id = ""
		return
	is_one_shot_active = true
	if track.name == FALLING_OBJECT_TARGET_TRACK:
		shoot_note(false)
	set_mood(maxf(mood - 0.25, -1.0))
	play_anim(Anim.caugh)


func _on_rhythm_base_note_hold_start(track: RhythmTrack, note: RhythmNote, _time_diff: float) -> void:
	if track.name == FALLING_OBJECT_TARGET_TRACK:
		set_mood(minf(mood + 0.25, 1.0))
		var target_falling_object: FallingObject = fall_object_manager.get_falling_object_by_note(note)
		is_one_shot_active = true
		shoot_note(true, target_falling_object)

	if track.name == HOLD_TRACK:
		set_mood(minf(mood + 0.25, 1.0))
		line_controller.start_hold(note.get_combined_id(), note.duration)
	current_hold_note_id = note.get_combined_id()

func _on_rhythm_base_note_hold_release(track: RhythmTrack, note: RhythmNote, _time_diff: float) -> void:
	if track.name != HOLD_TRACK:
		return
	line_controller.stop_hold(note.get_combined_id())
	current_hold_note_id = ""
	
func _on_rhythm_base_note_missed(track: RhythmTrack, _note: RhythmNote) -> void:
	if track.name != HOLD_TRACK && track.name != FALLING_OBJECT_TARGET_TRACK:
		return
	set_mood(maxf(mood - 0.2, -1.0))

func _on_rhythm_base_note_tap_hit(track: RhythmTrack, note: RhythmNote, _diff: float) -> void:
	if track.name != HOLD_TRACK && track.name != FALLING_OBJECT_TARGET_TRACK:
		return
	set_mood(minf(mood + 0.25, 1.0))

	if track.name == FALLING_OBJECT_TARGET_TRACK:
		var target_falling_object: FallingObject = fall_object_manager.get_falling_object_by_note(note)
		is_one_shot_active = true
		shoot_note(true, target_falling_object)

	elif track.name == HOLD_TRACK:
		current_hold_note_id = ""
		
func _on_rhythm_base_started_playing() -> void:
	start_moving()

func _on_rhythm_base_stopped_playing() -> void:
	stop_moving()

func _on_switch_pose_timer_timeout() -> void:
	start_switch_pose_timer()
	has_open_pose = !has_open_pose

func _on_timer_timeout() -> void:
	if is_one_shot_active:
		if is_moving:
			play_anim(get_idle_anim(mood))
		else:
			play_anim(Anim.RESET)
			anim_player.stop()
			
func set_mood(new_mood: float) -> void:
	mood = new_mood
	set_statue_by_mood()
	
func set_statue_by_mood() -> void:
	if mood >= 0.5:
		statue_animation_player.play("very_happy")
	elif mood >= 0.0:
		statue_animation_player.play("happy")
	elif mood > -0.5:
		statue_animation_player.play("sad")
	else:
		statue_animation_player.play("very_sad")
		
	
static func is_switchable_anim(anim: Anim) -> bool:
	match anim:
		Anim.RESET, Anim.breath, Anim.caugh, Anim.caugh_exhausted: return false
		
	return true

static func anim_to_str(anim: Anim) -> String:
	return Anim.keys()[anim]


func a_pressed() -> void:
	is_one_shot_active = false
	play_anim(Anim.sing)
		
func a_released() -> void:
	if is_moving:
		play_anim(get_idle_anim(mood))
	else:
		play_anim(Anim.RESET)
		anim_player.stop()
				
func b_pressed() -> void:
	play_anim(Anim.sing)
	is_one_shot_active = true
	anim_timer.start()	

func b_released() -> void:
	pass

func _on_ui_a_pressed() -> void:
	a_pressed()

func _on_ui_a_released() -> void:
	a_released()

func _on_ui_b_pressed() -> void:
	b_pressed()

func _on_ui_b_released() -> void:
	b_released()
