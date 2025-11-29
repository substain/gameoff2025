class_name CorrectNoteAudioPlayer
extends AudioStreamPlayer

var _music_position: float = 0.0

var target_volume: float

func _process(_delta: float) -> void:
	volume_linear = lerp(volume_linear, target_volume, 5.0* _delta)
	#print(self.name + ": ", volume_linear)

func _on_rhythm_base_note_tap_hit(_track: RhythmTrack, _note: RhythmNote, _time_diff: float) -> void:
	target_volume = 1.0

func _on_rhythm_base_note_hit(_track: RhythmTrack, _note: RhythmNote, _time_diff: float) -> void:
	target_volume = 1.0

func _on_rhythm_base_note_missed(_track: RhythmTrack, _note: RhythmNote) -> void:
	target_volume = 0.00001

func _on_rhythm_base_note_failed(_track: RhythmTrack, _note: RhythmNote) -> void:
	target_volume = 0.00001

func _on_rhythm_base_started_playing() -> void:
	play(_music_position)


func _on_rhythm_base_stopped_playing() -> void:
	_music_position = get_playback_position()
	stop()

func _on_rhythm_base_reset_progress() -> void:
	_music_position = 0.0
