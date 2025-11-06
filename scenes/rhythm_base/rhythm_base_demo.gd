extends Node

@onready var a: ColorRect = $"../A"
@onready var b: ColorRect = $"../B"
@onready var c: ColorRect = $"../C"

func _on_rhythm_base_event_triggered(event: RhythmTriggerEvent, time: float) -> void:
	match event.identifier:
		"RotateA":
			var tween: Tween = create_tween()
			tween.tween_property(a, "rotation", a.rotation + (PI*0.5), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
		"WiggleB":
			var tween: Tween = create_tween()
			for i: int in 10:
				tween.tween_property(b, "position", b.position + Vector2(randf(), randf()) * 25.0, 0.02)
		"ScaleC":
			var tween: Tween = create_tween()
			tween.tween_property(c, "scale", Vector2.ONE * 0.2, 0.15)
			tween.tween_property(c, "scale", Vector2.ONE * 1.0, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
 
