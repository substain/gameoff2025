extends Control

@onready var lines_container: Control = $LinesContainer

const CALIBRATION_LINE: PackedScene = preload("res://scenes/calibration/calibration_line.tscn")
const CALIBRATION_LABEL: PackedScene = preload("res://scenes/calibration/calibration_label.tscn")


@onready var rhythm_base: RhythmScene = $RhythmBase

var line_associtations: Dictionary[RhythmNote, Control] = {}

func _on_rhythm_base_event_triggered(event: RhythmTriggerEvent, time: float) -> void:
	var line: Control = CALIBRATION_LINE.instantiate()
	
	line.set_rhythm_data(rhythm_base._rhythm_data, rhythm_base.audio_stream_player)
	
	line.position.x = -get_viewport_rect().size.x/2.0
	
	lines_container.add_child(line)

	line_associtations[event.note] = line


func _on_rhythm_base_note_tap_hit(track: RhythmTrack, note: RhythmNote, time_diff: float) -> void:
	print("diff: %.2f" % time_diff)
	
	if note not in line_associtations:
		printerr("Not has no corresponding line segment??")
		return
		
	var line: Control = line_associtations[note]
	
	var label: Label = CALIBRATION_LABEL.instantiate()
	if is_zero_approx(time_diff):
		label.text = "PERFECT"
	elif time_diff < 0.0:
		label.text = "- %.2f" % abs(time_diff)
	else:
		label.text = "+ %.2f" % time_diff
		
	label.global_position = line.global_position
	
	add_child(label)
	
	var tween: Tween = label.create_tween()
	#tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 600.0, 4.0)
	#tween.tween_property(label, "scale", Vector2.ZERO, 1.0)
	#tween.set_parallel(false)
	tween.tween_interval(1.0)
	#tween.tween_callback(func() -> void:
	#	label.queue_free()
	#)
