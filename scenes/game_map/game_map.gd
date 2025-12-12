class_name GameMap
extends Node

enum LevelType {
	ZEN_GARDEN,
	GLOWSTICKS,
	ANGLER_FISH,
	SURFING,
	HOSPITAL
}

class LocationData:
	var texture_rect: TextureRect
	var label: RichTextLabel
	var location_overlay: TextureRect
	
	var texture_selfmodulate: Color
	var rtl_color: Color
	var tween: Tween = null

	
	func _init(
		texture_rect_new: TextureRect, 
		label_new: RichTextLabel,
		location_overlay_new: TextureRect,
		texture_selfmodulate_new: Color,
		rtl_color_new: Color) -> void:
			
		texture_rect = texture_rect_new
		label = label_new
		location_overlay = location_overlay_new
		texture_selfmodulate = texture_selfmodulate_new
		rtl_color = rtl_color_new
	
	
@export var autostart_countdown: bool = true
@export var use_random_order: bool = true
@export var num_random_selects: int = 25
@export var random_select_intervall: float = 0.3
@export var select_intervall_change_fac: float = -0.08

@export var location_textures: Dictionary[LevelType, TextureRect]

@export var actual_available_leveltypes: Array[LevelType]

@export var texture_inactive_color: Color = "b0b0b0"
@export var rtl_inactive_color: Color = "a6a6a6"

@export_file_path var zen_garden_level_path: String = ""
@export_file_path var surfing_level_path: String = ""
@export_file_path var angler_fish_level_path: String = ""
@export_file_path var glowsticks_level_path: String = ""
@export_file_path var hospital_level_path: String = ""

@export var timer: Timer
@export var countdown_button: Button

#@export var levelselection: Array[TextureRect]
#@export var level_buttons: Array[BaseButton] = []
var current_wheel_leveltypes: Array[LevelType] = []

var selected_level: int

var is_select_random: bool = false
var random_select_time: float = random_select_intervall
var current_select_intervall: float = random_select_intervall

var location_data: Dictionary[LevelType, LocationData] = {}

func _enter_tree() -> void:
	if autostart_countdown:
		countdown_button.visible = false
		
	for lvltype: LevelType in location_textures:
		var texture: TextureRect = location_textures[lvltype]
		var rtl: RichTextLabel = texture.find_child("*RTL", false)
		var loc_overlay: TextureRect = texture.find_child("*Overlay", false)
		var texture_modulate: Color = texture.self_modulate
		var rtl_color: Color = rtl.get("theme_override_colors/font_outline_color")
		rtl.text = "?"
		loc_overlay.visible = true
		loc_overlay.modulate = Color.TRANSPARENT
		
		var locdata: LocationData = LocationData.new(texture, rtl, loc_overlay, texture_modulate, rtl_color)
		location_data[lvltype] = locdata
		set_highlighted(lvltype, false)
	
func _ready() -> void:
	if autostart_countdown:
		start_randomize()

func _process(delta: float) -> void:
	#if countdown_button.disabled:	
		#var rounded_time:int = roundi(timer.time_left)
		#countdown_button.text = "Countdown:" + str(rounded_time)
	#

	if is_select_random:
		random_select_time -= delta
		if random_select_time < 0:
			num_random_selects -= 1
			select_random_level()
			if num_random_selects <= 0:
				pick_final_level()
			else:
				current_select_intervall = current_select_intervall * (1.0+select_intervall_change_fac)
				random_select_time = current_select_intervall
				
			

func switch_level(level_type: LevelType) -> void:
	var level_to_load_file_path: String = ""

	match level_type:
		LevelType.ZEN_GARDEN:
			level_to_load_file_path = zen_garden_level_path
		LevelType.SURFING:
			level_to_load_file_path = surfing_level_path
		LevelType.ANGLER_FISH:
			level_to_load_file_path = angler_fish_level_path
		LevelType.GLOWSTICKS:
			level_to_load_file_path = glowsticks_level_path
		LevelType.HOSPITAL:
			level_to_load_file_path = hospital_level_path
		
		_:
			push_warning("level type '", LevelType.keys()[level_type], "' has no implementation")
			return
	
	if level_to_load_file_path == "":
		push_warning("empty file path found for '", LevelType.keys()[level_type], "'")
		return

		
	get_tree().change_scene_to_file(level_to_load_file_path)

func _on_zen_garden_level_button_pressed() -> void:
	switch_level(LevelType.ZEN_GARDEN)

func _on_surf_level_button_pressed() -> void:
	switch_level(LevelType.SURFING)

func _on_angler_fish_level_button_pressed() -> void:
	switch_level(LevelType.ANGLER_FISH)

func _on_glowsticks_button_pressed() -> void:
	switch_level(LevelType.GLOWSTICKS)


func _on_button_pressed() -> void:
	start_randomize()
	
func start_randomize() -> void:
	if num_random_selects == 0:
		pick_final_level()
		return
	
	select_random_level()
	random_select_time = random_select_intervall
	current_select_intervall = random_select_intervall
	is_select_random = true
	
#func start_countdown() -> void:
	#timer.start()
	#countdown_button.disabled = true
	#countdown_button.text = "Countdown:" + str(timer.time_left)
	#countdown_button.set("theme_override_font_sizes/font_size", 25)
	#selected_level = randi_range(0, LevelType.values().size()-1)
	
	#levelselection[selected_level].visible = true
	
func _on_timer_timeout() -> void:
	switch_level(selected_level)

func select_random_level() -> void:
	#unhighlight current level first
	set_highlighted(selected_level, false)

	#pick new level
	if current_wheel_leveltypes.size() == 0:
		current_wheel_leveltypes.assign(location_data.keys())

	if use_random_order: 
		selected_level = current_wheel_leveltypes.pick_random()
	else:
		selected_level = current_wheel_leveltypes[0]
	current_wheel_leveltypes.erase(selected_level)
	(AudioController as AudioControllerClass).play_sfx(AudioControllerClass.SfxType.ACCEPT)
	
	#highlight new level
	set_highlighted(selected_level, true)
	
func pick_final_level() -> void:
	is_select_random = false
	set_highlighted(selected_level, false)
	(AudioController as AudioControllerClass).play_sfx(AudioControllerClass.SfxType.POPUP)

	selected_level = actual_available_leveltypes.pick_random()
	timer.start()
	set_highlighted(selected_level, true, false)
	location_data[selected_level].label.text = get_location_name(selected_level)
	var loc_overlay: TextureRect = location_data[selected_level].location_overlay
	var show_loc_overlay_tween: Tween = create_tween()
	show_loc_overlay_tween.tween_property(loc_overlay, "modulate:a", 1.0, 0.8)
	
func set_highlighted(level: LevelType, is_highlighted: bool, fadeout_highlight: bool = true) -> void:
	var loc_data: LocationData = location_data[level]
	loc_data.texture_rect.self_modulate = loc_data.texture_selfmodulate if is_highlighted else texture_inactive_color
	loc_data.label.set("theme_override_colors/font_outline_color", loc_data.rtl_color if is_highlighted else rtl_inactive_color)
	if is_instance_valid(loc_data.tween):
		loc_data.tween.kill()
				
	if is_highlighted && fadeout_highlight:
		
			
		loc_data.tween = create_tween()
		loc_data.tween.tween_property(loc_data.texture_rect, "self_modulate", texture_inactive_color, 0.4)
		loc_data.tween.tween_property(loc_data.label, "theme_override_colors/font_outline_color", rtl_inactive_color, 0.4)


func get_location_name(level: LevelType) -> String:
	return tr("leveltype." + (LevelType.keys()[level] as String).to_lower())
