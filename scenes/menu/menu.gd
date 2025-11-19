class_name Menu
extends Node

const VERSION_PLACEHOLDER: String = "[version]"

@export var set_game_title_from_project_settings: bool = true
@export_file_path("*.tscn") var start_scene_file_path: String

@export var is_pause_menu: bool = false

@export_category("internal nodes")
@export var start_menu: Control
@export var input_menu: InputMenu
@export var settings_menu: SettingsMenu
@export var credits: Credits

@export var title_label: RichTextLabel
@export var version_label: Label

@export var first_start_menu_item: BaseButton
@export var quit_button: BaseButton

@export var items_to_hide: Array[Control] = []

func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if !is_pause_menu:
		set_paused(false)
	
func _ready() -> void:
		
	for ctrl: Control in items_to_hide:
		ctrl.visible = false
	
	set_version()

	if set_game_title_from_project_settings:
		set_title_label_from_settings()
	
	quit_button.visible = !is_web_build()

	show_start_menu()

func show_start_menu() -> void:
	set_visible_only(start_menu, [input_menu, settings_menu, credits])
	first_start_menu_item.grab_focus.call_deferred()
	title_label.visible = true
	
func show_input_menu() -> void:
	set_visible_only(input_menu, [start_menu, settings_menu, credits])
	input_menu.grab_focus_deferred()
	title_label.visible = false

func show_settings_menu() -> void:
	set_visible_only(settings_menu, [input_menu, start_menu, credits])
	settings_menu.grab_focus_deferred()	
	title_label.visible = false

func show_credits() -> void:
	set_visible_only(credits, [input_menu, settings_menu, start_menu])
	credits.grab_focus_deferred()
	title_label.visible = false
	
func quit_game() -> void:
	await get_tree().create_timer(0.25).timeout
	get_tree().quit()
			
func set_version() -> void:
	version_label.text = version_label.text.replace(VERSION_PLACEHOLDER, str(ProjectSettings.get_setting("application/config/version")))
	
func set_title_label_from_settings() -> void:
	title_label.text = ProjectSettings.get_setting("application/config/name", "???")

func _on_start_game_button_pressed() -> void:
	get_tree().change_scene_to_file(start_scene_file_path)
	play_accept_sfx()

func _on_input_menu_button_pressed() -> void:
	show_input_menu()
	play_accept_sfx()

func _on_settings_menu_button_pressed() -> void:
	play_accept_sfx()
	show_settings_menu()
	
func _on_credits_button_pressed() -> void:
	play_accept_sfx()
	show_credits()

func _on_quit_button_pressed() -> void:
	play_accept_sfx()
	quit_game()
	
func _on_input_menu_back_button_pressed() -> void:
	play_accept_sfx()
	show_start_menu()

func _on_settings_menu_back_button_pressed() -> void:
	show_start_menu()
	play_accept_sfx()

func _on_credits_back_button_pressed() -> void:
	show_start_menu()
	play_accept_sfx()

func _on_calibration_button_pressed() -> void:
	play_accept_sfx()
	push_error("TODO: start calibration")

func _on_back_to_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func _on_continue_button_pressed() -> void:
	set_paused(false)
	self.visible = false

func set_paused(is_paused_new: bool) -> void:
	get_tree().paused = is_paused_new

static func set_visible_only(visible_node: CanvasItem, invisible_nodes: Array[CanvasItem]) -> void:
	for inv_node: CanvasItem in invisible_nodes:
		if inv_node == visible_node:
			continue
			
		inv_node.visible = false
	
	visible_node.visible = true
	
static func is_web_build() -> bool:
	return OS.has_feature("web")

func play_accept_sfx() -> void:
	AudioController.play_sfx(AudioController.SfxType.ACCEPT)
		
func play_hover_sfx() -> void:
	AudioController.play_sfx(AudioController.SfxType.HOVER)
