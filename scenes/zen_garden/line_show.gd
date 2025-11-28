class_name LineShow
extends Node2D

@export var curve_to_use: Curve2D
@export var debug_autostart: bool = false
@export	var target_path: Path2D
@export	var actual_pressed_path_follow: PathFollow2D
@export	var telegraph_path_follow: PathFollow2D
@export_category("internal nodes")
@export var actual_pressed_sprite: Sprite2D
@export var actual_pressed_line2d: Line2D
@export var actual_pressed_timer: Timer
@export var telegraph_sprite: Sprite2D
@export var telegraph_line2d: Line2D
@export var telegraph_timer: Timer

var is_activated: bool = false
var telegraph_point_idx: int = 0
var actual_pressed_point_idx: int = 0

func _ready() -> void:
	telegraph_line2d.clear_points()
	actual_pressed_line2d.clear_points()
	
	#TODO: delete
	if debug_autostart:
		start_telegraphing()
	

	telegraph_sprite.visible = false
	actual_pressed_sprite.visible = false
	
func _process(delta: float) -> void:
	if !is_activated:
		return
	
	if !telegraph_timer.is_stopped():
		telegraph_point_idx = _handle_draw_update(telegraph_point_idx, telegraph_timer, telegraph_line2d, telegraph_path_follow)
		
	if !actual_pressed_timer.is_stopped():
		actual_pressed_point_idx = _handle_draw_update(actual_pressed_point_idx, actual_pressed_timer, actual_pressed_line2d, actual_pressed_path_follow)

## returns the new point index
func _handle_draw_update(current_point_idx: int, timer: Timer, line_2d: Line2D, target_path_follow: PathFollow2D) -> int:
	var progress: float = 1.0 - (timer.time_left / timer.wait_time)
	
	target_path_follow.progress = progress
	var new_pos: Vector2 = target_path_follow.global_position

	if _is_above_next_point_idx(telegraph_point_idx, progress): #TODO maybe need new_pos instead of progress
		#TODO update index
		pass
		
	line_2d.set_point_position(current_point_idx, line_2d.to_local(new_pos))		
	
	return current_point_idx

func start_telegraphing() -> void:
	is_activated = true
	#WARNING this might make problems if we have more than one line in use! (e.g. one for telegraphing while the other is still being pressed)
	target_path.curve = curve_to_use
	
	telegraph_point_idx = _start_activation_for(telegraph_timer, telegraph_sprite, telegraph_line2d)

func start_activating() -> void:
	if !is_activated:
		#WARNING this might make problems if we have more than one line in use! (e.g. one for telegraphing while the other is still being pressed)
		target_path.curve = curve_to_use
		push_warning("at this point telegraphing is supposed to be started already?!")
		is_activated = true
	
	actual_pressed_point_idx = _start_activation_for(actual_pressed_timer, actual_pressed_sprite, actual_pressed_line2d)

# returns the new point index
func _start_activation_for(timer: Timer, sprite: Sprite2D, line_2d: Line2D) -> int:
	timer.start()
	sprite.visible = true
	line_2d.add_point(line_2d.to_local(curve_to_use.get_baked_points()[0]), 0)
	line_2d.add_point(line_2d.to_local(curve_to_use.get_baked_points()[0]), 1)
	return 1

func stop_activating() -> void:
	actual_pressed_timer.stop()
	
func _is_above_next_point_idx(point_idx: int, progress: float) -> bool:
	#TODO
	return false
