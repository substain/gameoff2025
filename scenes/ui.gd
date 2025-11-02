class_name UI
extends CanvasLayer



@onready var start: Button = $UIBase/MarginContainer/HBoxContainer/Start
@onready var stop: Button = $UIBase/MarginContainer/HBoxContainer/Stop

@onready var movable_level: MovableLevel = $"../MovableLevel"
@onready var player: Player = $"../Player"
@onready var game_message: Label = $GameMessage
@onready var base_audio_stream_player: AudioStreamPlayer = $"../BaseAudioStreamPlayer"
@onready var placement: Placement = $"../Placement"

func _ready() -> void:
	_on_stop_pressed.call_deferred()

func _on_start_pressed() -> void:
	start.text = "Restart"
	stop.disabled = false

	game_message.text = ""	
	
	movable_level.reset()
	movable_level.start()

	player.reset()
	player.start()

	base_audio_stream_player.play()
	placement.set_inactive()
			
func _on_stop_pressed() -> void:
	start.text = "Start"
	stop.disabled = true
	
	movable_level.stop()
	movable_level.reset()
	player.stop()
	player.reset()
	
	base_audio_stream_player.stop()

	placement.set_active()
	
func _on_player_player_died() -> void:
	_on_stop_pressed()
	game_message.text = "YOU DIED!"
