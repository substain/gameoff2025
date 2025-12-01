class_name GuideStreamPlayer
extends AudioStreamPlayer

var _music_position: float = 0.0

func _on_rhythm_base_reset_progress() -> void:
	_music_position = 0.0

func _on_rhythm_base_started_playing() -> void:
	play(_music_position)

func _on_rhythm_base_stopped_playing() -> void:
	_music_position = get_playback_position()
	stop()
