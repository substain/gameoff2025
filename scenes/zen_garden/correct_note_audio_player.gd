class_name CorrectNoteAudioPlayer
extends AudioStreamPlayer

var _music_position: float = 0.0

var target_volume: float

func _process(_delta: float) -> void:
	if is_equal_approx(volume_linear, target_volume):
		return
	#volume_linear = lerp(volume_linear, target_volume, 5.0* _delta)
	volume_linear = target_volume
	print(self.name + ": ", volume_linear)


func _on_rhythm_base_note_tap_hit(track: RhythmTrack, _note: RhythmNote, _time_diff: float) -> void:
	if track.name != SingingMonk.HOLD_TRACK && track.name != SingingMonk.FALLING_OBJECT_TARGET_TRACK:
		return
	target_volume = 1.0

func _on_rhythm_base_note_hit(track: RhythmTrack, _note: RhythmNote, _time_diff: float) -> void:
	if track.name != SingingMonk.HOLD_TRACK && track.name != SingingMonk.FALLING_OBJECT_TARGET_TRACK:
		return
	target_volume = 1.0

func _on_rhythm_base_note_missed(track: RhythmTrack, _note: RhythmNote) -> void:
	if track.name != SingingMonk.HOLD_TRACK && track.name != SingingMonk.FALLING_OBJECT_TARGET_TRACK:
		return
	target_volume = 0.00001

func _on_rhythm_base_note_failed(track: RhythmTrack, _note: RhythmNote) -> void:
	if track.name != SingingMonk.HOLD_TRACK && track.name != SingingMonk.FALLING_OBJECT_TARGET_TRACK:
		return
	
	target_volume = 0.00001

func _on_rhythm_base_started_playing() -> void:
	play(_music_position)


func _on_rhythm_base_stopped_playing() -> void:
	_music_position = get_playback_position()
	stop()

func _on_rhythm_base_reset_progress() -> void:
	_music_position = 0.0


func _on_rhythm_base_note_hold_start(track: RhythmTrack, _note: RhythmNote, _time_diff: float) -> void:
	if track.name != SingingMonk.HOLD_TRACK && track.name != SingingMonk.FALLING_OBJECT_TARGET_TRACK:
		return
	target_volume = 1.0


func _on_rhythm_base_note_hold_release(track: RhythmTrack, _note: RhythmNote, _time_diff: float) -> void:
	if track.name != SingingMonk.HOLD_TRACK && track.name != SingingMonk.FALLING_OBJECT_TARGET_TRACK:
		return
	target_volume = 0.00001
