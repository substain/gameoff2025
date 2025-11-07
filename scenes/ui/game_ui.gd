class_name GameUI 
extends CanvasLayer

signal start_pressed
signal stop_pressed
signal set_paused(is_paused: bool)
signal toggle_rhythm_ui(is_toggled_on: bool)

@export_category("internal nodes")
@export var start_button: Button
@export var pause_button: Button
@export var show_rhythm_ui_button: Button

func _ready() -> void:
	show_rhythm_ui_button.text = "Hide Rhyhthm UI" if show_rhythm_ui_button.button_pressed else "Show Rhyhthm UI"  

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

func _on_show_rhythm_ui_button_toggled(toggled_on: bool) -> void:
	toggle_rhythm_ui.emit(toggled_on)
	show_rhythm_ui_button.text = "Hide Rhyhthm UI" if toggled_on else "Show Rhyhthm UI"  
