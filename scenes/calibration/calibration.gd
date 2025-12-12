class_name Calibration
extends Control

const CALIBRATION_LINE: PackedScene = preload("res://scenes/calibration/calibration_line.tscn")
const CALIBRATION_LABEL: PackedScene = preload("res://scenes/calibration/calibration_label.tscn")

# Config
const MINIMUM_HITS: int = 8
# maximum sollte maximal die song länge sein
# sogar weniger, da nur getroffene taps zählen
# Ggf sollten wir einbauen, dass ein Song einfach neu starten kann
# ohne das wir die ganze Szene neu laden müssen
const MAXIMUM_HITS: int = 30
const CONSISTENCY_THRESHOLD: float = 0.05 # 50ms

signal calibration_finished(offset_value: float)

@export_category("internal nodes")
@export var input_hint_label: Label
@export var overlay: ColorRect
@export var consistency_label: Label
@export var final_label: Label
@export var fin_reset_button: Button
@export var fin_back_to_main_menu_button: Button
@export var mobile_ui: Control
@export var back_to_main_menu_button: Button

@onready var pause_menu: Menu = $PauseMenu
@onready var lines_container: Control = $LinesContainer
@onready var rhythm_base: RhythmScene = $RhythmBase

var line_associtations: Dictionary[RhythmNote, Control] = {}
var current_mean: float = 0.0
var offsets: Array[float] = []

var stopped: bool = false

func _ready() -> void:
	overlay.visible = false
	rhythm_base.start()
	SettingsIO.locale_changed.connect(translate_hint)
	update_consistency_label(0)
	translate_hint()
	handle_mobile()
	back_to_main_menu_button.text = tr("ui.calibration.cancel")

func handle_mobile() -> void:
	mobile_ui.visible = GameState.is_mobile

func _on_rhythm_base_event_triggered(event: RhythmTriggerEvent, _time: float) -> void:
	var line: CalibrationLine = CALIBRATION_LINE.instantiate() as CalibrationLine
	
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

func _on_rhythm_base_note_tap_hit(_track: RhythmTrack, note: RhythmNote, time_diff: float) -> void:
	print("diff: %.2f" % time_diff)
	
	if note not in line_associtations:
		printerr("Not has no corresponding line segment??")
		return
	
	# record attempt
	offsets.push_back(time_diff)
	if offsets.size() >= MINIMUM_HITS:
		var cd: ConsistencyData = _calculate_consistency(offsets)
		update_consistency_label(cd.deviation)
		print("consistency: mean=%.3f, deviation(MAD)=%.3f" % [cd.mean, cd.deviation])
			
		if cd.deviation <= CONSISTENCY_THRESHOLD:
			print("calibrated!")
			finish_calibration(cd.mean, cd.deviation, true)
		
		if offsets.size() >= MAXIMUM_HITS:
			# TODO: Allow the player to reset the calibration and also calibrate
			# at any time
			print("not really calibrated! but we take what we can get")
			finish_calibration(cd.mean, cd.deviation, false)

	else:
		update_consistency_label(0)

	back_to_main_menu_button.text = tr("ui.calibration.cancel") if offsets.size() < MINIMUM_HITS else tr("ui.calibration.finish")
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

func _on_rhythm_base_finished_playing() -> void:
	if stopped:
		return
	if offsets.size() >= MINIMUM_HITS:
		var cd: ConsistencyData = _calculate_consistency(offsets)
		update_consistency_label(cd.deviation)
		finish_calibration(cd.mean, cd.deviation, false)
		
	else:
		show_minimum_tries_message()
		
func finish_calibration(mean: float, deviation: float, is_good: bool) -> void:
	stopped = true
	calibration_finished.emit(mean)
	SettingsIO.set_calibration(mean)
	rhythm_base.stop()
	show_finished_overlay(1.0 - deviation, is_good)

	if is_good:
		await get_tree().create_timer(3.5).timeout
		return_to_main_menu()

			
func update_consistency_label(deviation: float) -> void:
	var num_samples: int = offsets.size()
	if num_samples < MINIMUM_HITS:
		consistency_label.text = "# "+str(num_samples)+"/"+str(MINIMUM_HITS)+""
		return

	consistency_label.text = to_consistency_str(1.0-deviation) + "% /" + to_consistency_str(1.0-CONSISTENCY_THRESHOLD) + "%"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_menu.visible = !pause_menu.visible
		pause_menu.set_paused(pause_menu.visible as bool)

func translate_hint() -> void:
	var text: String = tr("calibration.hint")
	var input_action_name: String = InputHandler.get_first_input_str_for_input_name(InputHandler.InputName.action_a)
	if GameState.is_mobile:
		input_action_name = InputHandler.get_mobile_action_name(InputHandler.InputName.action_a)
		
	input_hint_label.text = text.replace("[0]", input_action_name)

func _on_back_to_main_menu_button_pressed() -> void:
	if offsets.size() >= MINIMUM_HITS:
		var cd: ConsistencyData = _calculate_consistency(offsets)
		SettingsIO.set_calibration(cd.mean)
	return_to_main_menu()

func return_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func show_finished_overlay(consistency: float, is_good: bool) -> void:
	overlay.visible = true
	fin_reset_button.visible = !is_good
	fin_back_to_main_menu_button.visible = !is_good
	if is_good:
		final_label.text = tr("ui.calibration.finished_good").replace("[0]", to_consistency_str(consistency))
	else:
		final_label.text = tr("ui.calibration.finished_ok").replace("[0]", to_consistency_str(consistency))

func to_consistency_str(consistency: float) -> String:
	return str(snapped(consistency * 100, 0.1))

func show_minimum_tries_message() -> void:
	overlay.visible = true
	final_label.text = tr("ui.calibration.minimum_tries").replace("[0]", str(MINIMUM_HITS))
	fin_back_to_main_menu_button.text = tr("ui.calibration.cancel")

func _on_reset_button_pressed() -> void:
	get_tree().reload_current_scene()
