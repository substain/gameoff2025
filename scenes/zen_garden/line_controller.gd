class_name LineController
extends Node2D

@export var lines: Array[LineShow] = []

var available_lines: Array[LineShow]

func _ready() -> void:
	available_lines = lines.duplicate()

func get_next_line() -> LineShow:
	if available_lines.size() == 0:
		push_warning("could not get next line, there are no available lines!")
		return null
		
	var random_index: int = randi_range(0, available_lines.size() - 1)
	var line_show: LineShow = available_lines[random_index]
	available_lines.remove_at(random_index)
	return line_show
