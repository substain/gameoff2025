class_name SettingsMenu
extends Control

const MUTED_TR_KEY: String = "ui.settings.audio_value_muted"

signal back_button_pressed

@export var first_focus_item: Button

@export var locale_option_button: OptionButton
@export var fullscreen_button: CheckBox

@export var overall_slider: HSlider
@export var music_slider: HSlider
@export var sfx_slider: HSlider
@export var ambience_slider: HSlider

@export var overall_value_label: Label
@export var music_value_label: Label
@export var sfx_value_label: Label
@export var ambience_value_label: Label

@export var overall_mute_checkbox: CheckBox
@export var music_mute_checkbox: CheckBox
@export var sfx_mute_checkbox: CheckBox
@export var ambience_mute_checkbox: CheckBox

var fullscreen_active: bool


func _ready() -> void:
	if first_focus_item == null:
		push_warning("first_focus_item not set!")
	init_locale_options()
	load_values_from_settings()

func init_locale_options() -> void:
	for locale_item: SettingsIO.LocaleItem in SettingsIO.LocaleItem.values():
		@warning_ignore("static_called_on_instance")
		locale_option_button.add_item(get_locale_option_name(locale_item), locale_item as int)

func load_values_from_settings() -> void:
	locale_option_button.selected = SettingsIO.locale as int

	set_fullscreen_active(SettingsIO.fullscreen_active)

	overall_slider.set_value_no_signal(SettingsIO.overall_volume_linear)
	music_slider.set_value_no_signal(SettingsIO.music_volume_linear)
	sfx_slider.set_value_no_signal(SettingsIO.sfx_volume_linear)
	ambience_slider.set_value_no_signal(SettingsIO.ambience_volume_linear)
	
	set_percent_slider_value(overall_value_label, SettingsIO.overall_volume_linear)
	set_percent_slider_value(music_value_label, SettingsIO.music_volume_linear)
	set_percent_slider_value(sfx_value_label, SettingsIO.sfx_volume_linear)
	set_percent_slider_value(ambience_value_label, SettingsIO.ambience_volume_linear)
	
	if SettingsIO.overall_volume_muted:
		set_percent_slider_value_muted(overall_value_label)
	if SettingsIO.music_volume_muted:
		set_percent_slider_value_muted(music_value_label)
	if SettingsIO.sfx_volume_muted:
		set_percent_slider_value_muted(sfx_value_label)
	if SettingsIO.ambience_volume_muted:
		set_percent_slider_value_muted(ambience_value_label)
		
	overall_mute_checkbox.set_pressed_no_signal(SettingsIO.overall_volume_muted)
	music_mute_checkbox.set_pressed_no_signal(SettingsIO.music_volume_muted)
	sfx_mute_checkbox.set_pressed_no_signal(SettingsIO.sfx_volume_muted)
	ambience_mute_checkbox.set_pressed_no_signal(SettingsIO.ambience_volume_muted)

func set_percent_slider_value(label: Label, value_linear: float) -> void:
	label.text = str(roundi(value_linear * 100)) + "%"

func set_percent_slider_value_muted(label: Label) -> void:
	label.text = tr(MUTED_TR_KEY)

static func get_languagecode_fom_locale_uitext(locale_str: String) -> StringName:
	if locale_str.to_lower().contains("deutsch"):
		return &"de";
	else:
		return &"en";

static func get_short_locale(locale_item: SettingsIO.LocaleItem) -> String:
	return str(SettingsIO.LocaleItem.keys()[locale_item]).to_lower()

static func get_locale_option_name(locale_item: SettingsIO.LocaleItem) -> String:
	match locale_item:
		SettingsIO.LocaleItem.EN: return "English"
		SettingsIO.LocaleItem.DE: return "Deutsch"

	push_error("no locale option element for ", SettingsIO.LocaleItem.keys()[locale_item], " implemented")
	return "???"
	
func change_locale(locale_item: SettingsIO.LocaleItem) -> void:
	play_accept_sfx()
	TranslationServer.set_locale(get_short_locale(locale_item))

func set_fullscreen_active(is_active_new: bool) -> void:
	fullscreen_active = is_active_new
	
	@warning_ignore("static_called_on_instance")
	SettingsIO.set_fullscreen(is_active_new)
	SettingsIO.set_fullscreen_active(is_active_new, true)
	fullscreen_button.set_pressed_no_signal(fullscreen_active)

func grab_focus_deferred(control: Control = first_focus_item) -> void:
	control.grab_focus.call_deferred()

func play_accept_sfx() -> void:
	AudioController.play_sfx(AudioController.SfxType.ACCEPT)
		
func play_hover_sfx() -> void:
	AudioController.play_sfx(AudioController.SfxType.HOVER)

func _on_fullscreen_check_box_toggled(toggled_on: bool) -> void:
	play_accept_sfx()
	set_fullscreen_active(toggled_on)
	
func _on_locale_option_button_item_selected(index: int) -> void:
	play_accept_sfx()
	var locale_item: SettingsIO.LocaleItem = SettingsIO.LocaleItem.values()[index]
	change_locale(locale_item)
	SettingsIO.set_locale(locale_item)
	
func _on_overall_audio_h_slider_drag_ended(value_changed: bool) -> void:
	play_accept_sfx()
	if value_changed:
		SettingsIO.set_overall_volume(overall_slider.value)
		
func _on_music_audio_h_slider_drag_ended(value_changed: bool) -> void:
	play_accept_sfx()
	if value_changed:
		SettingsIO.set_music_volume(music_slider.value)
		
func _on_sfx_audio_h_slider_drag_ended(value_changed: bool) -> void:
	play_accept_sfx()
	if value_changed:
		SettingsIO.set_sfx_volume(sfx_slider.value)
		
func _on_ambience_audio_h_slider_drag_ended(value_changed: bool) -> void:
	play_accept_sfx()
	if value_changed:
		SettingsIO.set_ambience_volume(ambience_slider.value)
		
func _on_overall_audio_h_slider_value_changed(value: float) -> void:
	play_hover_sfx()
	SettingsIO.set_overall_volume(value, false)
	set_percent_slider_value(overall_value_label, value)
	AudioUtil.set_bus_volume(AudioUtil.AudioType.MASTER, value)
	
func _on_music_audio_h_slider_value_changed(value: float) -> void:
	play_hover_sfx()
	SettingsIO.set_music_volume(value, false)
	set_percent_slider_value(music_value_label, value)
	AudioUtil.set_bus_volume(AudioUtil.AudioType.MUSIC, value)
	
func _on_sfx_audio_h_slider_value_changed(value: float) -> void:
	play_hover_sfx()
	SettingsIO.set_sfx_volume(value, false)
	set_percent_slider_value(sfx_value_label, value)
	AudioUtil.set_bus_volume(AudioUtil.AudioType.SFX, value)
	
func _on_ambience_audio_h_slider_value_changed(value: float) -> void:
	play_hover_sfx()
	SettingsIO.set_ambience_volume(value, false)
	set_percent_slider_value(ambience_value_label, value)
	AudioUtil.set_bus_volume(AudioUtil.AudioType.AMBIENCE, value)

func _on_overall_audio_mute_check_box_toggled(toggled_on: bool) -> void:
	play_accept_sfx()
	SettingsIO.set_overall_volume_muted(toggled_on, true)
	if toggled_on:
		set_percent_slider_value_muted(overall_value_label)
	else:
		set_percent_slider_value(overall_value_label, SettingsIO.overall_volume_linear)		
	AudioUtil.set_bus_muted(AudioUtil.AudioType.MASTER, toggled_on)

func _on_music_audio_mute_check_box_toggled(toggled_on: bool) -> void:
	play_accept_sfx()
	SettingsIO.set_overall_volume_muted(toggled_on, true)
	if toggled_on:
		set_percent_slider_value_muted(music_value_label)
	else:
		set_percent_slider_value(music_value_label, SettingsIO.music_volume_linear)
	AudioUtil.set_bus_muted(AudioUtil.AudioType.MUSIC, toggled_on)
	
func _on_sfx_audio_mute_check_box_toggled(toggled_on: bool) -> void:
	play_accept_sfx()
	SettingsIO.set_overall_volume_muted(toggled_on, true)
	if toggled_on:
		set_percent_slider_value_muted(sfx_value_label)
	else:
		set_percent_slider_value(sfx_value_label, SettingsIO.sfx_volume_linear)
	AudioUtil.set_bus_muted(AudioUtil.AudioType.SFX, toggled_on)
		
func _on_ambience_audio_mute_check_box_toggled(toggled_on: bool) -> void:
	play_accept_sfx()
	SettingsIO.set_overall_volume_muted(toggled_on, true)
	if toggled_on:
		set_percent_slider_value_muted(ambience_value_label)
	else:
		set_percent_slider_value(ambience_value_label, SettingsIO.ambience_volume_linear)
	AudioUtil.set_bus_muted(AudioUtil.AudioType.AMBIENCE, toggled_on)
	
func _on_reset_button_pressed() -> void:
	play_accept_sfx()
	SettingsIO.reset()
	SettingsIO.apply_values()
	load_values_from_settings()
	
func _on_back_button_pressed() -> void:
	play_accept_sfx()
	back_button_pressed.emit()
