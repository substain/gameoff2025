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
var input_reassignment_key: InputHandler.InputName
var exit_key_tr_template: String = ""
var remap_key_tr_template: String = ""

var current_input_to_remap: InputHandler.InputName
var current_action_index: int = 0

func _ready() -> void:
	reassignment_overlay.visible = false
	remap_key_tr_template = press_remap_key_label.text
	exit_key_tr_template = press_exit_key_label.text
	if first_focus_item == null:
		push_warning("first_focus_item not set!")
	instantiate_inputs()
	
	#update_all_input_names()

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

	#for input_action: StringName in input_actions_to_instantiate:
		#var input_row: InputAssignmentRow = INPUT_ROW_SCENE.instantiate() as InputAssignmentRow
		#remap_row_parent.add_child(input_row)
		#input_row.init_from(input_action)
		##input_assign_rows[input_action] = input_row
		#
		#var iab_1: InputAssignButton = input_row.get_input_assign_button(false)
		#iab_1.on_pressed_input_assign.connect(start_input_reassignment)
		#input_assignment_buttons.append(iab_1)
#
		#var iab_2: InputAssignButton = input_row.get_input_assign_button(true)
		#iab_2.on_pressed_input_assign.connect(start_input_reassignment)
		#input_assignment_buttons.append(iab_2)

	
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
	waiting_for_reassignment = false
	reassignment_overlay.visible = false

func update_all_input_names() -> void:
	#TODO
	pass

func _input(in_event: InputEvent) -> void:
	if !waiting_for_reassignment:
		return
	
	get_viewport().set_input_as_handled()
	if in_event.is_action_pressed("cancel"):
		
	
	#if in_event is InputEventKey && (in_event as InputEventKey).pressed && (in_event as InputEventKey).keycode == KEY_ESCAPE:
		stop_reassignment()
		return
		
	if in_event is InputEventMouseMotion:
		return
		
	if in_event is InputEventJoypadMotion:
		return
		
		#var in_joy_motion_event: InputEventJoypadMotion = in_event as InputEventJoypadMotion
		#if in_joy_motion_event.axis_value < 0.3:
		#	return

	update_input_map_from_in(input_reassignment_key, in_event, current_action_index)
	update_button_from_input_event(reassign_button, in_event)
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
