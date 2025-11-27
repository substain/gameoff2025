class_name LineShow
extends Node2D

@export	var target_path: Path2D
@export var curve: Curve2D
@export_category("internal nodes")
@export var preview_sprite: Sprite2D
@export var line_sprite: Sprite2D
@export var preview_timer: Timer
@export var line_timer: Timer

var is_activated: bool = false

var preview_sprite_mat: ShaderMaterial
var line_sprite_mat: ShaderMaterial

func _ready() -> void:
	preview_sprite_mat = preview_sprite.material as ShaderMaterial
	line_sprite_mat = line_sprite.material as ShaderMaterial
	preview_sprite.visible = false
	line_sprite.visible = false
	
func _process(delta: float) -> void:
	if !preview_timer.is_stopped():
		var progress: float = (1.0 - preview_timer.time_left) / preview_timer.wait_time
		preview_sprite_mat.set_shader_parameter("progress", progress)

	if !line_timer.is_stopped():
		var progress: float = (1.0 - line_timer.time_left) / line_timer.wait_time
		line_sprite_mat.set_shader_parameter("progress", progress)

func start_telegraphing() -> void:
	preview_timer.start()
	preview_sprite.visible = true

func start_activating() -> void:
	line_timer.start()
	line_sprite.visible = true

func stop_activating() -> void:
	line_timer.stop()
