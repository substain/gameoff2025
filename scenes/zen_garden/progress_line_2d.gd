class_name ProgressLine2D
extends Line2D


@export var fadeout_on_finalize: bool = false
@export_category("internal nodes")
@export var sprite: Sprite2D
@export var timer: Timer
@export	var target_path: Path2D
@export	var path_follow: PathFollow2D

var curve_to_use: Curve2D

var is_activated: bool = false

var current_point_idx: int = 0
var previous_point: Vector2
var next_point: Vector2
var current_dist_squared: float
var pointer_activated: bool = false
var show_tween: Tween

func _ready() -> void:
	clear_points()
	sprite.visible = false
	path_follow.modulate.a = 0.0

func show_pointer() -> void:
	pointer_activated = true
	show_tween = create_tween()
	show_tween.tween_property(path_follow, "modulate:a", 1.0, 0.2)

func start_progressing(max_duration: float) -> void:
	is_activated = true
	
	timer.start(max_duration)
	sprite.visible = true
	var point_0: Vector2 = curve_to_use.get_baked_points()[0]
	add_point(point_0, 0)
	update_active_point_at(1, point_0)
	if !pointer_activated:
		show_pointer()
	
func _process(_delta: float) -> void:
	if !is_activated:
		return

	if !timer.is_stopped():
		_handle_draw_update()

func _handle_draw_update() -> int:
	var progress: float = 1.0 - (timer.time_left / timer.wait_time)
	
	path_follow.progress_ratio = progress
	var new_pos: Vector2 = path_follow.global_position
	var index_to_use: int = current_point_idx
	if previous_point.distance_squared_to(new_pos) >= current_dist_squared:
		set_point_position(current_point_idx, to_local(next_point))
		if current_point_idx + 1 < curve_to_use.point_count-1:
			update_active_point_at(current_point_idx + 1, to_local(new_pos))
		else:
			finalize(true)
	else:
		set_point_position(current_point_idx, to_local(new_pos))

	return index_to_use

func update_active_point_at(new_index: int, point: Vector2) -> void:
	current_point_idx = new_index
	add_point(point, new_index)
	previous_point = to_global(curve_to_use.get_point_position(new_index-1))
	next_point = to_global(curve_to_use.get_point_position(new_index))
	current_dist_squared = previous_point.distance_squared_to(next_point)

func stop_progressing() -> void:
	timer.stop()
	finalize(false)
	
func finalize(update_points: bool) -> void:
	if update_points:
		points = curve_to_use.get_baked_points()
	gradient = null

	if is_instance_valid(show_tween):
		show_tween.kill()

	show_tween = create_tween()
	show_tween.tween_property(path_follow, "modulate:a", 0.0, 0.5)
	
	if fadeout_on_finalize:
		show_tween.tween_property(sprite, "modulate:a", 0.0, 0.3)

func _on_timer_timeout() -> void:
	finalize(true)
