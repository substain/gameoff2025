extends ColorRect

var _data: RhythmData
var _player: AudioStreamPlayer

func _physics_process(_delta: float) -> void:
	if _data == null:
		queue_free()
		return

	if position.x < get_viewport_rect().size.x:
		position.x += 10.0 / _data.get_bps_at_time(_player.get_playback_position()) # get_viewport_rect().size.x 
	else:
		queue_free()

func set_rhythm_data(data: RhythmData, music_player: AudioStreamPlayer) -> void:
	_data = data
	_player = music_player
