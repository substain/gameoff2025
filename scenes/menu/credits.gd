class_name Credits
extends Control

const CREDITS_FILE_PATH: String = "res://data/credits.txt"
const ATTRIBUTION_FILE_PATH: String = "res://data/attributions.txt"

signal back_button_pressed

@export var enable_links: bool = true
@export var first_focus_item: Button

@export_category("internal nodes")
@export var game_label: Label
@export var godot_label: Label
@export var attributions_label: Label 
@export var attributions_separator: HSeparator 

@export var about_game_rtl: RichTextLabel
@export var about_godot_rtl: RichTextLabel
@export var attributions_rtl: RichTextLabel

func _ready() -> void:

	if first_focus_item == null:
		push_warning("first_focus_item not set!")
	set_credits_texts()

func set_credits_texts() -> void:
	var attributions_text: String = get_attributions_text_rich()
	game_label.text = ProjectSettings.get_setting("application/config/name", "Game") + " v" + str(ProjectSettings.get_setting("application/config/version"))
	godot_label.text = "Godot " + Engine.get_version_info()["string"]
	about_game_rtl.text = get_game_credits_text_rich()
	about_godot_rtl.text = get_godot_license_text_rich()
	if attributions_text.is_empty():
		attributions_label.visible = false
		attributions_rtl.visible = false
		attributions_separator.visible = false
	else:
		attributions_rtl.text = attributions_text

func _on_back_button_pressed() -> void:
	back_button_pressed.emit()
	
func grab_focus_deferred(control: Control = first_focus_item) -> void:
	control.grab_focus.call_deferred()
	
func play_accept_sfx() -> void:
	(AudioController as AudioControllerClass).play_sfx(AudioControllerClass.SfxType.ACCEPT)
		
func play_hover_sfx() -> void:
	(AudioController as AudioControllerClass).play_sfx(AudioControllerClass.SfxType.HOVER)
	
func get_game_credits_text_rich() -> String:
	if !FileAccess.file_exists(CREDITS_FILE_PATH):
		push_warning("Credits: Specified file '" + CREDITS_FILE_PATH + "' does not exist. Could not load credits")
		return ""
		
	var credits_file: FileAccess = FileAccess.open(CREDITS_FILE_PATH, FileAccess.READ);
	var credits_text: String = credits_file.get_as_text();
	credits_file.close();
	return credits_text
	
func get_attributions_text_rich() -> String:
	if !FileAccess.file_exists(ATTRIBUTION_FILE_PATH):
		push_warning("Credits: Specified file '" + ATTRIBUTION_FILE_PATH + "' does not exist. Could not load attributions")
		return ""
		
	var attributions_file: FileAccess = FileAccess.open(ATTRIBUTION_FILE_PATH, FileAccess.READ);
	var attributions_text: String = attributions_file.get_as_text();
	attributions_file.close();
	return attributions_text
	
func get_godot_license_text_rich() -> String:
	return Engine.get_license_text()

func _on_meta_clicked(meta: Variant) -> void:
	if !enable_links:
		return
	OS.shell_open(str(meta))
