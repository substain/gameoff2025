class_name ZenGardenSingingLevel
extends Node2D

@export_category("internal nodes")
@export var rhythm_scene: RhythmScene
@export var ui: GameUI

var audio_paused: bool = false
var audio_progressed: bool = false

func _ready() -> void:
	pass # Replace with function body.

func _on_ui_start_pressed() -> void:
	rhythm_scene.start()
	ui.set_audio_progressed(true)

func _on_ui_stop_pressed() -> void:
	rhythm_scene.stop()
	ui.set_audio_progressed(false)

func _on_ui_set_paused(is_paused: bool) -> void:
	rhythm_scene.set_paused(is_paused)		
	ui.set_audio_paused(is_paused)
