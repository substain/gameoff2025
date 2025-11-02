class_name UI
extends CanvasLayer



@onready var start: Button = $UIBase/MarginContainer/HBoxContainer/Start
@onready var stop: Button = $UIBase/MarginContainer/HBoxContainer/Stop

@onready var movable_level: MovableLevel = $"../MovableLevel"
@onready var player: Player = $"../Player"
@onready var game_message: Label = $GameMessage
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

	Globals.sound_manager.start_music()
	Globals.on_start_game.emit()
	placement.set_inactive()
			
func _on_stop_pressed() -> void:
	start.text = "Start"
	stop.disabled = true
	
	movable_level.stop()
	movable_level.reset()
	player.stop()
	player.reset()
	
	Globals.sound_manager.stop_music()
	Globals.on_stop_game.emit()
	placement.set_active()
	
func _on_player_player_died() -> void:
	_on_stop_pressed()
	game_message.text = "YOU DIED!"


func _on_kick_pressed() -> void:
	placement.set_snippet_type(SoundSnippet.SoundType.KICK)


func _on_clap_pressed() -> void:
	#placement.set_snippet_type(SoundSnippet.SoundType.CLAP)
	pass
	


func _on_m_down_pressed() -> void:
	placement.set_snippet_type(SoundSnippet.SoundType.M1)
