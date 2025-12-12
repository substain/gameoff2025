class_name FinalOverlay
extends Control

@export var final_label: Label
@export var score_hbc: HBoxContainer
@export var score_value_label: Label
@export var final_rating_tag: Label
@export var fin_retry_button: Button
@export var fin_back_to_main_menu_button: Button

@export var thresholds: Array[float] = [-3.0, -0.8, -0.1, 0.3, 0.6, 0.92]


var max_score: int

func _ready() -> void:
	final_label.modulate.a = 0.0
	score_hbc.modulate.a = 0.0
	final_rating_tag.modulate.a = 0.0
	fin_retry_button.modulate.a = 0.0
	fin_back_to_main_menu_button.modulate.a = 0.0

	score_value_label.text = "0"

func set_max_score(max_score_new: int) -> void:
	max_score = max_score_new

func fade_in_result(score: int) -> void:
	visible = true
	
	_fade_in_final_label()
	await get_tree().create_timer(1.0).timeout
	
	await _fade_in_score(score)
	await get_tree().create_timer(1.0).timeout
	
	_fade_in_rating_tag(score)
	await get_tree().create_timer(1.0).timeout
	
	_fade_in_buttons()


func _fade_in_final_label() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(final_label, "modulate:a", 1.0, 0.5)

func _fade_in_score(score: int) -> Signal:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(score_hbc, "modulate:a", 1.0, 0.5)
	tween.tween_method(tween_count_up_score.bind(score), 0.0, 1.0, 2.0)
	return tween.finished
	
func _fade_in_rating_tag(score: int) -> void:
	var rating_tag_str: String = tr(get_label_by_score(score))
	final_rating_tag.visible_characters = 0
	final_rating_tag.text = rating_tag_str
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(final_rating_tag, "modulate:a", 1.0, 0.5)
	tween.tween_property(final_rating_tag, "visible_characters", rating_tag_str.length(), 1.0)

func _fade_in_buttons() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(fin_retry_button, "modulate:a", 1.0, 0.5)
	tween.tween_property(fin_back_to_main_menu_button, "modulate:a", 1.0, 0.5)

func tween_count_up_score(progress: float, target_score: int) -> void:
	score_value_label.text = str(snappedi(lerp(0, target_score, progress) as float, 1))

func get_label_by_score(score: int) -> String:
	var rel_score: float = float(mini(score, max_score)) / float(max_score)
	print("mini(score, max_score)", mini(score, max_score), ", max_score:", max_score, ", rel_score: ", rel_score)
	if thresholds.size() == 0 || rel_score < thresholds[0]:
		return "ui.rating.tester"
	if thresholds.size() == 1 || rel_score < thresholds[1]:
		return "ui.rating.try_bad"
	if thresholds.size() <= 2 || rel_score < thresholds[2]:
		return "ui.rating.did_you_press"
	if thresholds.size() <= 3 || rel_score < thresholds[3]:
		return "ui.rating.improvable"
	if thresholds.size() <= 4 || rel_score < thresholds[4]:
		return "ui.rating.okay"
	if thresholds.size() <= 5 || rel_score < thresholds[5]:
		return "ui.rating.great"
	
	return "ui.rating.fantastic"
