class_name ZenPlayerPathFollow
extends PathFollow2D

const SPEED: float = 200

@export var autostart: bool = true
@export var drawn_lines: Node2D
@export var interpolation_time: float = 0.15
@export var zen_line_scene: PackedScene

var current_line_points: Array[Vector2] = []

var is_running: bool = false
var is_drawing: bool = false

var current_line: Line2D = null

var current_interpolation: float = 0.0

func _ready() -> void:
	if autostart:
		start()	

func _process(delta: float) -> void:

	var progress_ratio_before: float = progress_ratio	
	if progress_ratio >= 1.0:
		stop()
		return
	
	if is_running:
		progress += delta * SPEED
		if progress_ratio_before > progress_ratio:
			stop()
			return
	
	if is_drawing:
		draw_zen_line(delta)
		
		
func draw_zen_line(delta: float) -> void:
	current_interpolation += delta
	if current_interpolation >= interpolation_time:
		current_interpolation = 0.0
		current_line_points.append(global_position)
		current_line.points = current_line_points
	else:
		var temp_points: Array[Vector2] = current_line_points.duplicate()
		temp_points.append(global_position)
		current_line.points = temp_points
		
	print("is drawing zen line")
		

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action1"):
		is_drawing = true
		current_interpolation = 0.0
		current_line = zen_line_scene.instantiate()
		drawn_lines.add_child(current_line)
		current_line_points.clear()

	elif event.is_action_released("action1"):
		is_drawing = false
		current_line = null

func start() -> void:
	is_running = true
	
func stop() -> void:
	is_running = false
