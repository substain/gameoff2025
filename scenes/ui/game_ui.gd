class_name GameUI 
extends CanvasLayer

signal start_pressed
signal stop_pressed
signal set_paused(is_paused: bool)

@export_category("internal nodes")
@export var start_button: BaseButton
@export var pause_button: BaseButton

func _ready() -> void:
	pass

func set_audio_paused(is_paused: bool) -> void:
	pause_button.text = "Unpause" if is_paused else "Pause"

func set_audio_progressed(is_progressed: bool) -> void:
	start_button.text = "Restart" if is_progressed else "Start"
	
func _on_start_pressed() -> void:
	start_pressed.emit()

func _on_stop_pressed() -> void:
	stop_pressed.emit()

func _on_pause_toggled(toggled_on: bool) -> void:
	set_paused.emit(toggled_on)
