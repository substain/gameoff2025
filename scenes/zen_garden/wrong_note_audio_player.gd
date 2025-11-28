class_name WrongNoteAudioPlayer
extends AudioStreamPlayer

func _on_rhythm_base_note_failed(_track: RhythmTrack, _note: RhythmNote) -> void:
	play()
