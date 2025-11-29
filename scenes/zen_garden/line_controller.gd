class_name LineController
extends Node2D

@export var randomize_lines: bool = true
@export var lines: Array[LineShow] = []

var available_lines: Array[LineShow]

var current_id_mappings: Dictionary[String, LineShow]

var current_id: String = ""

func _ready() -> void:
	available_lines = lines.duplicate()

func get_next_line() -> LineShow:
	if available_lines.size() == 0:
		push_warning("could not get next line, there are no available lines!")
		return null
	
	var next_index: int = 0
	if randomize_lines:
		next_index = randi_range(0, available_lines.size() - 1)
	var line_show: LineShow = available_lines[next_index]
	available_lines.remove_at(next_index)
	return line_show

func start_telegraph(id: String, duration: float, telegraph_offset: float) -> void:
	var next_line: LineShow = get_next_line()
	if next_line == null:
		return
	
	current_id_mappings[id] = next_line
	
	next_line.start_telegraphing(duration, telegraph_offset)
	
func start_hold(id: String, max_duration: float) -> void:
	if !current_id_mappings.has(id):
		push_warning("lineshow is not available for given id ('", id, "')!")
		return
	
	current_id = id
			
	current_id_mappings[current_id].start_activating(max_duration)

func stop_hold(id: String) -> void:
	if !current_id_mappings.has(id):
		return
	current_id_mappings[id].stop_activating()

func stop_hold_current() -> void:
	stop_hold(current_id)
