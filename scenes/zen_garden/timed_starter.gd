class_name TimedStarter
extends Node2D


@export var target_lines: Array[Line2D]

@export var target_times: Array[float]
#@export var target_durations: Array[float]

@export var preview_progress: float = 0.1

@export var time_progress: float = 0.0

var current_line: Line2D = null
var current_index: int = 0

var next_start_time: float = 0.0
var next_end_time: float = 0.0

func _ready() -> void:
	if target_times.size() < target_lines.size() + 1:
		push_warning("target times should cover durations as well, i.e. a size of [target_lines.size()+1] is expected")
	
	update_current_line(current_index)

func _process(delta: float) -> void:
	if target_lines.size() == 0:
		return
	
	time_progress += delta
	if current_line == null:
		return
	
	if time_progress < next_start_time:
		return
		
	if time_progress >= next_end_time:

		if current_index >= target_lines.size()-1:
			return
		else:
			current_index += 1
			update_current_line(current_index)
	
	var progress: float = inverse_lerp(next_start_time, next_end_time, time_progress)
	(current_line.material as ShaderMaterial).set_shader_parameter("end_min", progress)
	(current_line.material as ShaderMaterial).set_shader_parameter("end_max", min(progress + preview_progress, 1.0))
		
func update_current_line(target_line_index: int) -> void:
	current_line = target_lines[target_line_index]
	
	next_start_time = target_times[target_line_index]
	next_end_time = target_times[target_line_index+1]
