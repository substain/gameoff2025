class_name GameUI 
extends CanvasLayer

signal start_pressed
signal stop_pressed
signal set_paused(is_paused: bool)
signal toggle_rhythm_ui(is_toggled_on: bool)

@export_category("internal nodes")
@export var start_button: Button
@export var pause_button: Button
@export var show_rhythm_ui_button: Button
@export var status_label: Label
@export var progress_bar: ProgressBar
@export var hit_label: RichTextLabel
@export var missed_label: RichTextLabel
@export var failed_label: RichTextLabel
@export var warning_label: RichTextLabel

var is_stopped: bool = false
var is_track_in_progress: bool = false

## TODO: keep the counting logic somewhere else instead of in the ui
var current_hits: int = 0
var current_misses: int = 0
var current_fails: int = 0

var hit_text_template: String
var missed_text_template: String
var failed_text_template: String

func _ready() -> void:
	GameState.ui = self
	show_rhythm_ui_button.text = "Hide Rhyhthm UI" if show_rhythm_ui_button.button_pressed else "Show Rhyhthm UI"  
	hit_text_template = hit_label.text
	missed_text_template = missed_label.text
	failed_text_template = failed_label.text
	reset_note_statistics()



func set_progress(progress: float) -> void:
	progress_bar.value = progress * 100
	
func set_audio_paused(is_paused: bool) -> void:
	pause_button.text = "Unpause" if is_paused else "Pause"
	is_track_in_progress = is_paused
	update_status_label()
	
func set_audio_in_progress(in_progress: bool) -> void:
	start_button.text = "Restart" if in_progress else "Start"
	is_track_in_progress = in_progress
	update_status_label()

func _on_start_pressed() -> void:
	start_pressed.emit()

func _on_stop_pressed() -> void:
	stop_pressed.emit()

func _on_pause_toggled(toggled_on: bool) -> void:
	set_paused.emit(toggled_on)

func _on_show_rhythm_ui_button_toggled(toggled_on: bool) -> void:
	toggle_rhythm_ui.emit(toggled_on)
	show_rhythm_ui_button.text = "Hide Rhyhthm UI" if toggled_on else "Show Rhyhthm UI"  

func _on_rhythm_base_started_playing() -> void:
	is_stopped = false
	is_track_in_progress = true
	start_button.text = "Restart"
	update_status_label()
	
func _on_rhythm_base_stopped_playing() -> void:
	is_stopped = true
	pause_button.text = "Unpause" if is_track_in_progress else "Pause"
	update_status_label()
	
func _on_rhythm_base_reset_progress() -> void:
	if is_stopped:
		is_track_in_progress = false
	start_button.text = "Start"
	update_status_label()
	reset_note_statistics()
		
func update_status_label() -> void:
	if is_stopped:
		status_label.text = "-paused-" if is_track_in_progress else "-stopped-"	
	else:
		status_label.text = "-running-"

func _on_rhythm_base_note_hit(track: RhythmTrack, note: RhythmNote) -> void:
	set_current_hits(current_hits + 1)

func _on_rhythm_base_note_tap_hit(track: RhythmTrack, note: RhythmNote) -> void:
	set_current_hits(current_hits + 1)

func _on_rhythm_base_note_failed(track: RhythmTrack, note: RhythmNote) -> void:
	set_current_fails(current_fails + 1)

func _on_rhythm_base_note_missed(track: RhythmTrack, note: RhythmNote) -> void:
	set_current_misses(current_misses + 1)

func reset_note_statistics() -> void:
	set_current_hits(0)
	set_current_misses(0)
	set_current_fails(0)
	
func set_current_hits(amount: int) -> void:
	current_hits = amount
	hit_label.text = hit_text_template.replace("{amount}", str(current_hits))

func set_current_fails(amount: int) -> void:
	current_fails = amount
	failed_label.text = failed_text_template.replace("{amount}", str(current_fails))

func set_current_misses(amount: int) -> void:
	current_misses = amount
	missed_label.text = missed_text_template.replace("{amount}", str(current_misses))

func _on_back_to_map_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_map/game_map.tscn")
