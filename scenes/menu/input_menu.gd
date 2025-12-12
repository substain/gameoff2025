class_name InputMenu
extends Control

signal back_button_pressed
@export var cancel_input_action: InputHandler.InputName

@export_category("internal nodes")
@export var first_focus_item: Button
@export var input_parent: Control
@export var reassignment_overlay: Control
@export var press_remap_key_label: Label
@export var press_exit_key_label: Label

var waiting_for_reassignment: bool = false
var reassign_button: Button = null
var exit_key_tr_template: String = ""
var remap_key_tr_template: String = ""

var current_input_to_remap: InputHandler.InputName
var current_action_index: int = 0



var remap_buttons: Dictionary[InputHandler.InputName, Dictionary] = {}  # Dictionary[int, InputEvent]

func _ready() -> void:
	reassignment_overlay.visible = false
	remap_key_tr_template = press_remap_key_label.text
	exit_key_tr_template = press_exit_key_label.text
	if first_focus_item == null:
		push_warning("first_focus_item not set!")
	instantiate_inputs()

func instantiate_inputs() -> void:
	var remappable_inputs: Array[InputHandler.InputName] = InputHandler.remappable_inputs

	for remappable_input: InputHandler.InputName in remappable_inputs:
		var remappable_input_str: String = InputHandler.input_name_to_str(remappable_input)
		var input_events: Array[InputEvent] = InputMap.action_get_events(remappable_input_str)
		#add_label(tr(to_tr_key(remappable_input_str)))			
		add_label(InputHandler.to_tr_key(remappable_input_str))
			
		var first_input_button: Button
		if input_events.size() == 0:
			first_input_button = add_empty_button()
		else:
			first_input_button = add_input_button(input_events[0])
			
		first_input_button.pressed.connect(_on_input_button_pressed.bind(remappable_input, 0, first_input_button))
		
		var second_input_button: Button		
		if input_events.size() <= 1:
			second_input_button = add_empty_button()
		else:
			second_input_button = add_input_button(input_events[1])

		second_input_button.pressed.connect(_on_input_button_pressed.bind(remappable_input, 1, second_input_button))

		remap_buttons[remappable_input] = {0: first_input_button, 1: second_input_button}
	
func _on_input_button_pressed(input_name: InputHandler.InputName, action_index: int, button: Button) -> void:
	current_input_to_remap = input_name
	translate()
	reassignment_overlay.visible = true
	print("input button for ", input_name, " pressed, action index: ", action_index)
	waiting_for_reassignment = true
	reassign_button = button
	reassign_button.text = "<?>"
	current_action_index = action_index

func grab_focus_deferred(control: Control = first_focus_item) -> void:
	control.grab_focus.call_deferred()

func stop_reassignment() -> void:
	update_button_by_input_event(reassign_button, current_action_index, InputMap.action_get_events(InputHandler.input_name_to_str(current_input_to_remap)))
	waiting_for_reassignment = false
	reassignment_overlay.visible = false

func update_all_input_names() -> void:
	for input_name: InputHandler.InputName in remap_buttons.keys():
		var input_events: Array[InputEvent] = InputMap.action_get_events(InputHandler.input_name_to_str(input_name))
		update_button_by_input_event(remap_buttons[input_name][0] as Button, 0, input_events)
		update_button_by_input_event(remap_buttons[input_name][1] as Button, 1, input_events)
	
func update_button_by_input_event(button: Button, index: int, input_events: Array[InputEvent]) -> void:
	if input_events.size() <= index:
		update_button_from_input_event(button, null)
	else:
		update_button_from_input_event(button, input_events[index])

func _input(in_event: InputEvent) -> void:
	if !waiting_for_reassignment:
		return
	
	get_viewport().set_input_as_handled()
	if in_event.is_action_pressed("cancel"):
		stop_reassignment()
		return
		
	if in_event is InputEventMouseMotion:
		return
		
	if in_event is InputEventJoypadMotion:
		return
		
		#var in_joy_motion_event: InputEventJoypadMotion = in_event as InputEventJoypadMotion
		#if in_joy_motion_event.axis_value < 0.3:
		#	return

	update_input_map_from_in(current_input_to_remap, in_event, current_action_index)
	update_button_from_input_event(reassign_button, in_event)
	SettingsIO.update_input_settings(current_input_to_remap, in_event, current_action_index, true)
	#get_viewport().set_input_as_handled() # needed?
	stop_reassignment()

func update_button_from_input_event(button: Button, new_key_event: InputEvent) -> void:
	var text_to_use: String = "..."
	if new_key_event != null:
		text_to_use = InputHandler.input_event_to_str(new_key_event)
		#stop_reassignment
	button.text = text_to_use
	
func add_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	input_parent.add_child(label)
	return label

func add_input_button(input_event: InputEvent) -> Button:
	var button: Button = Button.new()
	update_button_from_input_event(button, input_event)
	input_parent.add_child(button)
	return button
	
func add_empty_button() -> Button:
	var button: Button = Button.new()
	update_button_from_input_event(button, null)
	input_parent.add_child(button)
	return button
	
func _on_reset_button_pressed() -> void:
	play_accept_sfx()
	reset_inputs()
	
func _on_back_button_pressed() -> void:
	play_accept_sfx()
	back_button_pressed.emit()
	
func reset_inputs() -> void:
	InputMap.load_from_project_settings()
	SettingsIO.reset_inputs(true)
	update_all_input_names()

func play_accept_sfx() -> void:
	(AudioController as AudioControllerClass).play_sfx(AudioControllerClass.SfxType.ACCEPT)
		
func play_hover_sfx() -> void:
	(AudioController as AudioControllerClass).play_sfx(AudioControllerClass.SfxType.HOVER)


func translate() -> void:
	press_remap_key_label.text = tr(remap_key_tr_template).replace("[0]", tr(InputHandler.to_tr_key(InputHandler.input_name_to_str(current_input_to_remap))))
	press_exit_key_label.text = tr(exit_key_tr_template).replace("[0]", InputHandler.get_first_input_str_for_input_name(cancel_input_action))
	
static func update_input_map_from_in(input_name: InputHandler.InputName, new_input_event: InputEvent, index: int) -> void:
	update_input_map_from_ins(InputHandler.input_name_to_str(input_name), new_input_event, index)
	
static func update_input_map_from_ins(input_name_str: String, new_input_event: InputEvent, index: int) -> void:
	var input_events: Array[InputEvent] = InputMap.action_get_events(input_name_str)
	if input_events.size() <= index:
		InputMap.action_add_event(input_name_str, new_input_event)
		return

	input_events[index] = new_input_event
		
	InputMap.action_erase_events(input_name_str)
	for i: int in input_events.size():
		InputMap.action_add_event(input_name_str, input_events[i])
