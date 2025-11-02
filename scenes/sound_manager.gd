class_name SoundManager extends Node

@onready var base_audio_stream_player: AudioStreamPlayer = $BaseAudioStreamPlayer
@onready var m_1_audio_stream_player: AudioStreamPlayer = $M1AudioStreamPlayer
@onready var clap_audio_stream_player: AudioStreamPlayer = $ClapAudioStreamPlayer
@onready var kick_audio_stream_player: AudioStreamPlayer = $KickAudioStreamPlayer

func _ready() -> void:
	Globals.sound_manager = self

func start_music() -> void:
	base_audio_stream_player.play()

func stop_music() -> void:
	base_audio_stream_player.stop()

func play_kick() -> void:
	kick_audio_stream_player.play()

func play_clap() -> void:
	clap_audio_stream_player.play()
	
func play_m1() -> void:
	m_1_audio_stream_player.play()
	#
#func play_m2() -> void:
	#m_2_audio_stream_player.play()
