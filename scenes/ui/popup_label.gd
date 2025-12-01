class_name PopupLabel
extends Label

const SHOW_TWEEN_TIME: float = 0.2
const HIDE_TWEEN_TIME: float = 0.4


@export var timer: Timer

var tween: Tween

func _ready() -> void:
	#modulate = Color.TRANSPARENT
	pass

func start(duration: float) -> void:
	start_show()
	timer.start(duration)

func _on_timer_timeout() -> void:
	start_hide()

func start_show() -> void:
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	await tween.finished
	
func start_hide() -> void:
	if is_instance_valid(tween):
		tween.kill()
		
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()
