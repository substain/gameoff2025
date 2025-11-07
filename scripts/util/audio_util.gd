class_name AudioUtil 
extends Object
	
enum AudioType
{
	MASTER,
	MUSIC,
	SFX,
	AMBIENCE
}

static func set_bus_volume(audio_type: AudioType, volume_linear: float) -> void:
	var vol_to_use: float = volume_linear
	if vol_to_use <= 0:
		vol_to_use = 0.00001
	var bus_index: int = AudioServer.get_bus_index(AudioUtil.get_audio_type_string(audio_type))	
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(vol_to_use))
	#set_ui_value_by_audio_type(audio_type, volume_linear)
	
static func set_bus_muted(audio_type: AudioType, is_muted_new: bool) -> void:
	var bus_index: int = AudioServer.get_bus_index(AudioUtil.get_audio_type_string(audio_type))
	AudioServer.set_bus_mute(bus_index, is_muted_new)
	
static func is_bus_muted(audio_type: AudioType) -> bool:
	var bus_index: int = AudioServer.get_bus_index(AudioUtil.get_audio_type_string(audio_type))
	return AudioServer.is_bus_mute(bus_index)
	
static func get_audio_type_string(audio_type: AudioType) -> String:
	match audio_type:
		AudioType.MASTER:
			return "Master"
		AudioType.MUSIC:
			return "Music"
		AudioType.SFX:
			return "SFX"
		AudioType.AMBIENCE:
			return "Ambience"
			
	push_warning("Audio type " + str(audio_type) + " not implemented...")
	return "Unknown Audio Type"
	
## Returns the best audio player in the given array. This will directly return an audio stream player if it is not playing.
## Otherwise it favors audio stream players that have progressed the most.
## Note: This is untyped due to AudioStreamPlayer, AudioStreamPlayer2D and AudioStreamPlayer3D not sharing a common base class.
static func get_most_free_audio_stream_player(audio_stream_players: Array) -> Node:
	var most_progress: float = 0
	var most_progress_player: Node = null
	for target_player: Node in audio_stream_players:
		if _is_free(target_player):
			return target_player
		
		var current_progress: float = _get_progress(target_player)
		if current_progress >= most_progress:
			most_progress = current_progress
			most_progress_player = target_player
			
	return most_progress_player

## Returns the first audio player in the given array that is not playing, or null if there is no free audio player.
## Note: This is untyped due to AudioStreamPlayer, AudioStreamPlayer2D and AudioStreamPlayer3D not sharing a common base class.
static func get_free_audio_stream_player_or_null(target_audio_players: Array) -> Node:
	var free_players: Array = target_audio_players.filter(_is_free)
	if free_players.size() > 0:
		return free_players[0]
	return null
	
static func _is_free(audio_stream_player: Node) -> bool:
	@warning_ignore("unsafe_property_access")
	return audio_stream_player.playing || audio_stream_player.stream == null

static func _get_progress(audio_stream_player: Node) -> float:
	@warning_ignore("unsafe_property_access")
	@warning_ignore("unsafe_method_access")
	return audio_stream_player.get_playback_position() / audio_stream_player.stream.get_length()
	

static func collect_audio_stream_player3D_in_children(node: Node) -> Array[AudioStreamPlayer3D]:
	var res: Array[AudioStreamPlayer3D] = []
	for child: Node in node.get_children():
		var current_progress: Array[AudioStreamPlayer3D]= collect_audio_stream_player3D_in_children(child)
		res.append_array(current_progress)
		
	if node is AudioStreamPlayer3D:
		res.append(node)
		
	return res
	
static func collect_audio_stream_player2D_in_children(node: Node) -> Array[AudioStreamPlayer2D]:
	var res: Array[AudioStreamPlayer2D] = []
	for child: Node in node.get_children():
		var current_progress: Array[AudioStreamPlayer2D]= collect_audio_stream_player2D_in_children(child)
		res.append_array(current_progress)
		
	if node is AudioStreamPlayer2D:
		res.append(node)
		
	return res
	
static func collect_audio_stream_player_in_children(node: Node) -> Array[AudioStreamPlayer]:
	var res: Array[AudioStreamPlayer] = []
	for child: Node in node.get_children():
		var current_progress: Array[AudioStreamPlayer]= collect_audio_stream_player_in_children(child)
		res.append_array(current_progress)
		
	if node is AudioStreamPlayer:
		res.append(node)
		
	return res
