class_name InputHandler
extends Object

enum InputName {
	debug_start_track,
	debug_toggle_note_ui,
	debug_increase_note_ui_speed,
	debug_decrease_note_ui_speed,
	debug_reset_note_ui_speed,
	
	action_a, 
	action_b,
	action_c,
	
	pause,
	cancel
}

const DEBUG_START_TRACK: String = "debug_start_track"
const DEBUG_TOGGLE_NOTE_UI: String = "debug_toggle_note_ui"
const DEBUG_INCREASE_NOTE_UI_SPEED: String = "debug_increase_note_ui_speed"
const DEBUG_DECREASE_NOTE_UI_SPEED: String = "debug_decrease_note_ui_speed"
const DEBUG_RESET_NOTE_UI_SPEED: String = "debug_reset_note_ui_speed"

const ACTION_A: String = "action_a"
const ACTION_B: String = "action_b"
const ACTION_C: String = "action_c"

const PAUSE: String = "pause"

const ALL_ACTIONS: Array[String] = [ACTION_A, ACTION_B, ACTION_C]

const remappable_inputs: Array[InputName] = [
	InputName.action_a,	
	InputName.action_b,	
	InputName.pause,
]

const action_inputs: Array[InputName] = [
	InputName.action_a,
	InputName.action_b,
	InputName.action_c,
]

static func get_all_inputs_as_string() -> Array[String]:
	var all_actions: Array[String]
	all_actions.assign(InputName.keys())
	return all_actions

static func get_all_remappable_inputs_as_string() -> Array[String]:
	return get_as_string_array(remappable_inputs)
	
static func get_all_action_inputs_as_string() -> Array[String]:
	return get_as_string_array(action_inputs)

static func get_as_string_array(inputs: Array[InputName]) -> Array[String]:
	var input_strings: Array[String]
	for input: InputName in inputs:
		input_strings.push_back(input_name_to_str(input))
	return input_strings

static func input_name_to_str(input_name: InputName) -> String:
	return InputName.keys()[input_name]

static func input_event_to_str(input_event: InputEvent) -> String:
	if input_event is InputEventMouseButton:
		(input_event as InputEventMouseButton).double_click = false
		return (input_event as InputEventMouseButton).as_text()
	elif input_event is InputEventKey:
		var iek: InputEventKey = (input_event as InputEventKey)
		var keycode: int = iek.keycode
		if keycode == 0:
			keycode = DisplayServer.keyboard_get_keycode_from_physical(iek.physical_keycode)
		return OS.get_keycode_string(keycode) #
	else:
		@warning_ignore("unsafe_method_access")
		return input_event.as_text_key_label()
		
static func get_first_input_str_for_input_name(input_name: InputHandler.InputName) -> String:
	return input_event_to_str(get_first_input_for_input_name(input_name))

static func get_first_input_for_input_name(input_name: InputHandler.InputName) -> InputEvent:
	return get_first_input_for(input_name_to_str(input_name))
	
static func get_first_input_for(input_name_str: String) -> InputEvent:
	var input_events: Array[InputEvent] = InputMap.action_get_events(input_name_str);
	if input_events.size() == 0:
		return null
	
	return input_events[0];

static func to_tr_key(input_name: String) -> String:
	return "input."+input_name
