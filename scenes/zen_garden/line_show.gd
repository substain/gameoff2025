class_name LineShow
extends Node2D

@export var curve_to_use: Curve2D
@export_category("internal nodes")
@export var telegraph_line_2d: ProgressLine2D
@export var actual_pressed_line_2d: ProgressLine2D
@export var target_path: Path2D
@onready var input_hint_label: Label = $InputHintLabel
@onready var telegraph_timer: Timer = $TelegraphTimer

func _ready() -> void:
	telegraph_line_2d.curve_to_use = curve_to_use
	actual_pressed_line_2d.curve_to_use = curve_to_use
	input_hint_label.global_position = actual_pressed_line_2d.path_follow.global_position

func _process(_delta: float) -> void:
	#TODO: update time left
	## translate()
	pass

func start_telegraphing(max_duration: float, time_left: float) -> void:
	telegraph_line_2d.start_progressing(max_duration)
	actual_pressed_line_2d.show_pointer()
	target_path.curve = curve_to_use
	telegraph_timer.start(time_left)
	
func start_activating(max_duration: float) -> void:
	actual_pressed_line_2d.start_progressing(max_duration)

func stop_activating() -> void:
	actual_pressed_line_2d.stop_progressing()


func translate_text() -> void:
	pass
