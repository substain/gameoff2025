class_name LineShow
extends Node2D

@export var curve_to_use: Curve2D
@export_category("internal nodes")
@export var telegraph_line_2d: ProgressLine2D
@export var actual_pressed_line_2d: ProgressLine2D
@export var target_path: Path2D
@onready var input_hint_label: Label = $InputHintLabel
@onready var telegraph_timer: Timer = $TelegraphTimer

var time_left: String = ""

func _ready() -> void:
	input_hint_label.visible = false
	telegraph_line_2d.curve_to_use = curve_to_use
	actual_pressed_line_2d.curve_to_use = curve_to_use
	SettingsIO.locale_changed.connect(translate_text)

func _process(_delta: float) -> void:
	if !telegraph_timer.is_stopped():
		time_left = str(snapped(telegraph_timer.time_left, 0.1))
		translate_text()

func start_telegraphing(max_duration: float, time_left: float) -> void:
	input_hint_label.visible = true
	#input_hint_label.global_position = actual_pressed_line_2d.path_follow.global_position
	telegraph_line_2d.start_progressing(max_duration)
	actual_pressed_line_2d.show_pointer()
	target_path.curve = curve_to_use
	telegraph_timer.start(time_left)
	
func start_activating(max_duration: float) -> void:
	actual_pressed_line_2d.start_progressing(max_duration)

func stop_activating() -> void:
	input_hint_label.visible = false
	actual_pressed_line_2d.stop_progressing()

func translate_text() -> void:
	var text: String = tr("telegraph_button")
	#var input_action: String = tr(InputHandler.to_tr_key(InputHandler.input_name_to_str(InputHandler.InputName.action_b)))
	var input_action_name: String = InputHandler.get_first_input_str_for_input_name(InputHandler.InputName.action_a)
	input_hint_label.text = text.replace("[0]", input_action_name).replace("[1]", str(time_left))


func _on_telegraph_timer_timeout() -> void:
	input_hint_label.visible = false
