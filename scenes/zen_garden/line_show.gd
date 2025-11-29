class_name LineShow
extends Node2D

@export var curve_to_use: Curve2D
@export	var target_path: Path2D
@export	var actual_pressed_path_follow: PathFollow2D
@export	var telegraph_path_follow: PathFollow2D
@export_category("internal nodes")
@export var telegraph_line_2d: ProgressLine2D
@export var actual_pressed_line_2d: ProgressLine2D

func _ready() -> void:
	telegraph_line_2d.curve_to_use = curve_to_use
	telegraph_line_2d.target_path = target_path
	telegraph_line_2d.target_path_follow = telegraph_path_follow
	actual_pressed_line_2d.curve_to_use = curve_to_use
	actual_pressed_line_2d.target_path = target_path
	actual_pressed_line_2d.target_path_follow = actual_pressed_path_follow


func start_telegraphing(max_duration: float) -> void:
	telegraph_line_2d.start_progressing(max_duration)
	target_path.curve = curve_to_use
	
func start_activating(max_duration: float) -> void:
	actual_pressed_line_2d.start_progressing(max_duration)

func stop_activating() -> void:
	actual_pressed_line_2d.stop_progressing()
