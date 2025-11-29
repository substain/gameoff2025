class_name WrongNoteAudioPlayer
extends AudioStreamPlayer

func _on_rhythm_base_note_failed(track: RhythmTrack, _note: RhythmNote) -> void:
	if track.name != SingingMonk.HOLD_TRACK && track.name != SingingMonk.FALLING_OBJECT_TARGET_TRACK:
		return
	play()
