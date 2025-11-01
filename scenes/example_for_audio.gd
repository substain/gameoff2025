class_name ExampleForAudio
extends Control

@onready var fmod_event_emitter_2d: FmodEventEmitter2D = $FmodEventEmitter2D

func _ready() -> void:
	pass
	
func _on_stop_music_button_pressed() -> void:
	fmod_event_emitter_2d.stop()

func _on_start_music_button_pressed() -> void:
	fmod_event_emitter_2d.play()
