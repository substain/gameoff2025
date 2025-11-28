## Autoload: SettingsIO
class_name SettingsIOClass # to allow for typed access
extends Node

enum LocaleItem {
	EN, 
	DE	
}

signal locale_changed

const SETTINGS_PATH: String = "user://settings.save"
const FULLSCREEN_IS_BORDERLESS: bool = true

const SAVE_INPUT_PATH: String = "user://inputs.save"
const INPUTS_SECTION: String = "Input"

var inputs_file: ConfigFile
var inputs_saveable: bool = true

var overall_volume_linear: float = 0.75
var overall_volume_muted: bool = false
var music_volume_linear: float = 1
var music_volume_muted: bool = false
var sfx_volume_linear: float = 1
var sfx_volume_muted: bool = false
var guide_music_volume_linear: float = 1
var guide_music_volume_muted: bool = false

var locale: LocaleItem = LocaleItem.EN

var fullscreen_active: bool = false

var input_remaps: Dictionary = {}

var skip_intro_active: bool = false

var input_calibration_offset: float = 0.0

func _ready() -> void:
	if is_web_build():
		apply_web_build_settings()
	
	inputs_file = ConfigFile.new();	
	load_from_file()
	load_inputs_from_file()
	apply_values()
	
func apply_values() -> void:
	AudioUtil.set_bus_volume(AudioUtil.AudioType.MASTER, overall_volume_linear)
	AudioUtil.set_bus_volume(AudioUtil.AudioType.MUSIC, music_volume_linear)
	AudioUtil.set_bus_volume(AudioUtil.AudioType.SFX, sfx_volume_linear)
	AudioUtil.set_bus_volume(AudioUtil.AudioType.GUIDE_MUSIC, guide_music_volume_linear)
	AudioUtil.set_bus_muted(AudioUtil.AudioType.MASTER, overall_volume_muted)
	AudioUtil.set_bus_muted(AudioUtil.AudioType.MUSIC, music_volume_muted)
	AudioUtil.set_bus_muted(AudioUtil.AudioType.SFX, sfx_volume_muted)
	AudioUtil.set_bus_muted(AudioUtil.AudioType.GUIDE_MUSIC, guide_music_volume_muted)
	
	TranslationServer.set_locale(to_short_locale(locale))
	set_fullscreen(fullscreen_active)

func apply_web_build_settings() -> void:
	pass

func reset(do_save: bool = true) -> void:
	set_skip_intro_active(false, false)
	
	set_overall_volume(0.75, false)
	set_music_volume(1, false)
	set_sfx_volume(1, false)
	set_guide_music_volume(1, false)
	set_overall_volume_muted(false, false)
	set_music_volume_muted(false, false)
	set_sfx_volume_muted(false, false)
	set_guide_music_volume_muted(false, false)
	set_calibration(0.0, false)

	set_locale(LocaleItem.EN, false)
	set_fullscreen_active(false, false)
	
	if do_save:
		save_to_file()
		
func reset_inputs(do_save: bool = true) -> void:
	input_remaps = {}
	if do_save:
		save_inputs_to_file()
		
func save_to_file() -> void:
	var settings_file_access: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	var save_dict: Dictionary = {
		"overall_volume": overall_volume_linear,
		"music_volume": music_volume_linear,
		"sfx_volume": sfx_volume_linear,
		"guide_music_volume_linear": guide_music_volume_linear,
		"overall_volume_muted": overall_volume_muted,
		"music_volume_muted": music_volume_muted,
		"sfx_volume_muted": sfx_volume_muted,
		"guide_music_volume_muted": guide_music_volume_muted,
		"locale": locale,
		"fullscreen_active": fullscreen_active,
		"skip_intro_active": skip_intro_active,
		"input_calibration_offset": input_calibration_offset
	}
	
	var json_string: String = JSON.stringify(save_dict)
	settings_file_access.store_line(json_string)
	
func load_from_file() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return # We don't have a file to load.

	var save_game: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	while save_game.get_position() < save_game.get_length():
		var json_string: String = save_game.get_line()
		var json: JSON = JSON.new()
		var parseResult: Error = json.parse(json_string)
		if not parseResult == OK:
			push_warning("JSON Parse Error: '" + json.get_error_message() + "'  at line " + str(json.get_error_line()))
			continue
		var save_dict: Dictionary = json.get_data()
##
		if save_dict.has("overall_volume_linear"):
			overall_volume_linear = save_dict["overall_volume_linear"]
		if save_dict.has("music_volume_linear"):
			music_volume_linear = save_dict["music_volume_linear"]
		if save_dict.has("sfx_volume_linear"):
			sfx_volume_linear = save_dict["sfx_volume_linear"]
		if save_dict.has("guide_music_volume_linear"):
			guide_music_volume_linear = save_dict["guide_music_volume_linear"]
		if save_dict.has("overall_volume_muted"):
			overall_volume_muted = save_dict["overall_volume_muted"]
		if save_dict.has("music_volume_muted"):
			music_volume_muted = save_dict["music_volume_muted"]
		if save_dict.has("sfx_volume_muted"):
			sfx_volume_muted = save_dict["sfx_volume_muted"]
		if save_dict.has("guide_music_volume_muted"):
			guide_music_volume_muted = save_dict["guide_music_volume_muted"]
		if save_dict.has("locale"):
			locale = save_dict["locale"]
		if save_dict.has("fullscreen_active"):
			fullscreen_active = save_dict["fullscreen_active"]
		if save_dict.has("skip_intro_active"):
			skip_intro_active = save_dict["skip_intro_active"]
		if save_dict.has("input_calibration_offset"):
			input_calibration_offset = save_dict["input_calibration_offset"]
				
func save_inputs_to_file() -> void:
	if !inputs_saveable:
		return;
	inputs_file.set_value(INPUTS_SECTION, "input_remaps", input_remaps)
	var err: Error = inputs_file.save(SAVE_INPUT_PATH)
	#	input_remaps = {}
	if err != OK:
		push_error("could not save inputs to file " + SAVE_INPUT_PATH + ". Error was " + str(err))
		inputs_saveable = false

func load_inputs_from_file() -> void:
	if not FileAccess.file_exists(SAVE_INPUT_PATH):
		return # We don't have a file to load.

	var err: Error = inputs_file.load(SAVE_INPUT_PATH)
	input_remaps = {}
	if err != OK:
		push_error("cannot load inputs from '" + SAVE_INPUT_PATH + "'")
		return
	
	input_remaps = inputs_file.get_value(INPUTS_SECTION, "input_remaps")
		
func update_input_settings(input_key: String, in_event: InputEvent, do_save: bool = true) -> void:
	if input_remaps == null:
		input_remaps = {}
	input_remaps[input_key] = in_event
	if do_save:
		save_inputs_to_file()

func set_overall_volume(vol_new: float, do_save: bool = true) -> void:
	overall_volume_linear = vol_new
	if do_save:
		save_to_file()

func set_music_volume(vol_new: float, do_save: bool = true) -> void:
	music_volume_linear = vol_new
	if do_save:
		save_to_file()
		

func set_sfx_volume(vol_new: float, do_save: bool = true) -> void:
	sfx_volume_linear = vol_new
	if do_save:
		save_to_file()
		

func set_guide_music_volume(vol_new: float, do_save: bool = true) -> void:
	guide_music_volume_linear = vol_new
	if do_save:
		save_to_file()

func set_overall_volume_muted(overall_volume_muted_new: bool, do_save: bool = true) -> void:
	overall_volume_muted = overall_volume_muted_new
	if do_save:
		save_to_file()

func set_music_volume_muted(music_volume_muted_new: bool, do_save: bool = true) -> void:
	music_volume_muted = music_volume_muted_new
	if do_save:
		save_to_file()

func set_sfx_volume_muted(sfx_volume_muted_new: bool, do_save: bool = true) -> void:
	sfx_volume_muted = sfx_volume_muted_new
	if do_save:
		save_to_file()

func set_guide_music_volume_muted(guide_music_volume_muted_new: bool, do_save: bool = true) -> void:
	guide_music_volume_muted = guide_music_volume_muted_new
	if do_save:
		save_to_file()

func set_locale(locale_new: LocaleItem, do_save: bool = true) -> void:
	locale = locale_new
	locale_changed.emit()
	if do_save:
		save_to_file()

func set_fullscreen_active(fs_active_new: bool, do_save: bool = true) -> void:
	fullscreen_active = fs_active_new
	if do_save:
		save_to_file()

func set_skip_intro_active(skip_intro_active_new: bool, do_save: bool = true) -> void:
	skip_intro_active = skip_intro_active_new
	if do_save:
		save_to_file()
	
func set_calibration(calibration_new: float, do_save: bool = true) -> void:
	input_calibration_offset = calibration_new
	if do_save:
		save_to_file()
	
	
static func set_fullscreen(is_fullscreen: bool) -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, FULLSCREEN_IS_BORDERLESS)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

static func to_short_locale(locale_item: LocaleItem) -> String:
	return str(SettingsIO.LocaleItem.keys()[locale_item]).to_lower()
	
static func is_web_build() -> bool:
	return OS.has_feature("web")
