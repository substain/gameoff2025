class_name WrongNoteAudioPlayer
extends AudioStreamPlayer

func _on_rhythm_base_note_failed(track: RhythmTrack, note: RhythmNote) -> void:
	play()
