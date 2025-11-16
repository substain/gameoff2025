extends Control

signal calibration_finished(offset_value: float)

# Config
const MINIMUM_HITS: int = 10
# maximum sollte maximal die song länge sein
# sogar weniger, da nur getroffene taps zählen
# Ggf sollten wir einbauen, dass ein Song einfach neu starten kann
# ohne das wir die ganze Szene neu laden müssen
const MAXIMUM_HITS: int = 40
const CONSISTENCY_THRESHOLD: float = 0.05 # 50ms

var offsets: Array[float] = []

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

class ConsistencyData:
	extends RefCounted
	
	var mean: float = 0.0
	var deviation: float = 0.0
	
	func _init(m: float = 0.0, d: float = 0.0) -> void:
		mean = m
		deviation = d

func _calculate_consistency(_offsets: Array[float]) -> ConsistencyData:
	if _offsets.is_empty():
		return ConsistencyData.new()
		
	var consistency: ConsistencyData = ConsistencyData.new()
	
	# mean
	var sum: float = 0.0
	for val: float in _offsets:
		sum += val
	
	consistency.mean = sum / _offsets.size()
	
	# mean absolute deviation
	# https://en.wikipedia.org/wiki/Average_absolute_deviation
	var abs_dev_sum: float = 0.0
	for val: float in _offsets:
		abs_dev_sum += abs(val - consistency.mean)
		
	consistency.deviation = abs_dev_sum / offsets.size()
	
	return consistency

func _on_rhythm_base_note_tap_hit(track: RhythmTrack, note: RhythmNote, time_diff: float) -> void:
	print("diff: %.2f" % time_diff)
	
	if note not in line_associtations:
		printerr("Not has no corresponding line segment??")
		return
	
	# record attempt
	offsets.push_back(time_diff)
	if offsets.size() >= MINIMUM_HITS:
		var cd: ConsistencyData = _calculate_consistency(offsets)
		
		print("consistency: mean=%.3f, deviation(MAD)=%.3f" % [cd.mean, cd.deviation])
			
		if cd.deviation <= CONSISTENCY_THRESHOLD:
			print("calibrated!")
			calibration_finished.emit(cd.mean)
			SettingsIO.input_calibration_offset = cd.mean
			# TODO: Exit/stop calibration
		
		if offsets.size() >= MAXIMUM_HITS:
			# TODO: Allow the player to reset the calibration and also calibrate
			# at any time
			print("not really calibrated! but we take what we can get")
			calibration_finished.emit(cd.mean)
			SettingsIO.input_calibration_offset = cd.mean
			# TODO: Exit/stop calibration
		
			
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
