class_name ZenPlayerPathFollow
extends PathFollow2D

const SPEED: float = 200

@export var drawn_lines: Node2D
@export var interpolation_time: float = 0.15
@export var zen_line_scene: PackedScene
@export var telegraphed_path_follow: PathFollow2D

var current_line_points: Array[Vector2] = []

var is_running: bool = false
var is_drawing: bool = false

var current_line: Line2D = null

var current_interpolation: float = 0.0

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:

	var progress_ratio_before: float = progress_ratio	
	#if progress_ratio >= 1.0:
		#stop()
		#return
	#
	if is_running:
		progress += delta * SPEED
		#if progress_ratio_before > progress_ratio:
			#stop()
			#return
	
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
	pass
	#return
	#if event.is_action_pressed(InputHandler.ACTION_A):
		#is_drawing = true
		#current_interpolation = 0.0
		#current_line = zen_line_scene.instantiate()
		#drawn_lines.add_child(current_line)
		#current_line_points.clear()
#
	#elif event.is_action_released(InputHandler.ACTION_A):
		#is_drawing = false
		#current_line = null

func start() -> void:
	is_running = true
	
func stop() -> void:
	is_running = false

func get_telegraphed_position(time_offset: float) -> Vector2:
	telegraphed_path_follow.progress = progress + (time_offset * SPEED)
	return telegraphed_path_follow.global_position


func _on_rhythm_base_started_playing() -> void:
	start()


func _on_rhythm_base_stopped_playing() -> void:
	stop()


func _on_rhythm_base_reset_progress() -> void:
	progress_ratio = 0.0
