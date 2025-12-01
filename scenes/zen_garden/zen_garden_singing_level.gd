class_name ZenGardenSingingLevel
extends Node2D

@export var autostart: bool = true
@export_category("internal nodes")
@export var rhythm_scene: RhythmScene

var audio_paused: bool = false
var audio_progressed: bool = false

func _ready() -> void:
	if autostart:
		rhythm_scene.start()

func _on_ui_start_pressed() -> void:
	rhythm_scene.start()

func _on_ui_stop_pressed() -> void:
	rhythm_scene.stop()

func _on_ui_set_paused(is_paused: bool) -> void:
	rhythm_scene.set_paused(is_paused)		

func _on_ui_toggle_rhythm_ui(is_toggled_on: bool) -> void:
	rhythm_scene.set_ui_visible(is_toggled_on)
	
