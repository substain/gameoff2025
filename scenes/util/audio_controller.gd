## Autoload: AudioController (scene)
class_name AudioControllerClass # to allow for typed access
extends Node

enum SfxType {
	ACCEPT, 
	HOVER,
	POPUP
}

@export_category("internal nodes")
@export var accept_audio_stream_player: AudioStreamPlayer
@export var hover_audio_stream_player: AudioStreamPlayer
@export var popup_audio_stream_player: AudioStreamPlayer

func _ready() -> void:
	pass

func play_sfx(sfx_type: SfxType) -> void:
	match sfx_type:
		SfxType.ACCEPT:
			accept_audio_stream_player.play()
			
		SfxType.HOVER:
			hover_audio_stream_player.play()
			
		SfxType.POPUP:
			popup_audio_stream_player.play()
