class_name InputMenu
extends Control

signal back_button_pressed

@export var first_focus_item: Button

var waiting_for_reassignment: bool = false
var reassign_button: Button = null
var input_reassignment_key: String = "move_up"

func _ready() -> void:
	if first_focus_item == null:
		push_warning("first_focus_item not set!")
	update_all_input_names()

func grab_focus_deferred(control: Control = first_focus_item) -> void:
	control.grab_focus.call_deferred()

func start_reassignment(input_key: String, button: Button) -> void:
	waiting_for_reassignment = true
	input_reassignment_key = input_key
	reassign_button = button
	reassign_button.text = "press a button"
	
func stop_reassignment() -> void:
	waiting_for_reassignment = false

func update_all_input_names() -> void:
	#TODO
	pass

func _input(in_event: InputEvent) -> void:
	if !waiting_for_reassignment:
		return
	
	get_viewport().set_input_as_handled()
	
	if in_event is InputEventKey && (in_event as InputEventKey).pressed && (in_event as InputEventKey).keycode == KEY_ESCAPE:
		stop_reassignment()
		return
		
	if in_event is InputEventMouseMotion:
		return
		
	if in_event is InputEventJoypadMotion:
		return
		
		#var in_joy_motion_event: InputEventJoypadMotion = in_event as InputEventJoypadMotion
		#if in_joy_motion_event.axis_value < 0.3:
		#	return

	update_input_map(input_reassignment_key, in_event)
	update_button(reassign_button, in_event)
	#get_viewport().set_input_as_handled() # needed?
	stop_reassignment()

func update_button(button: Button, new_key_event: InputEvent) -> void:
	if new_key_event == null:
		stop_reassignment()
		return
	
	if new_key_event is InputEventMouseButton:
		(new_key_event as InputEventMouseButton).double_click = false
		button.text = (new_key_event as InputEventMouseButton).as_text()
	elif new_key_event is InputEventKey:
		var iek: InputEventKey = (new_key_event as InputEventKey)
		var keycode: int = iek.keycode
		if keycode == 0:
			keycode = DisplayServer.keyboard_get_keycode_from_physical(iek.physical_keycode)
		button.text = OS.get_keycode_string(keycode) #
	else:
		@warning_ignore("unsafe_call_argument")
		button.text = new_key_event.as_text_key_label()

static func get_first_input_for(input_name: String) -> InputEvent:
	var input_events: Array[InputEvent] = InputMap.action_get_events(input_name);
	if input_events.size() == 0:
		return null
	
	return input_events[0];
	
static func update_input_map(input_key: String, input_event: InputEvent) -> void:
	var input_events: Array[InputEvent] = InputMap.action_get_events(input_key);
	if input_events.size() == 0:
		InputMap.action_add_event(input_key, input_event);
		return
		
	InputMap.action_erase_events(input_key)
	InputMap.action_add_event(input_key, input_event);
	for i: int in input_events.size():
		if i == 0:
			continue
		InputMap.action_add_event(input_key, input_events[i]);
	
func _on_reset_button_pressed() -> void:
	play_accept_sfx()
	reset_inputs()
	
func _on_back_button_pressed() -> void:
	play_accept_sfx()
	back_button_pressed.emit()
	
func reset_inputs() -> void:
	InputMap.load_from_project_settings();
	update_all_input_names()

func play_accept_sfx() -> void:
	AudioController.play_sfx(AudioController.SfxType.ACCEPT)
		
func play_hover_sfx() -> void:
	AudioController.play_sfx(AudioController.SfxType.HOVER)
