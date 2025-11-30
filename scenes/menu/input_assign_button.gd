class_name InputAssignButton extends Button

signal on_pressed_input_assign(source: Button, input_key: String)

@export var input_key: String
@export var use_icon: bool = false

var rtl: RichTextLabel = null

func _ready() -> void:
	pressed.connect(on_pressed)
	if use_icon:
		rtl = RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.set_anchors_preset(Control.PRESET_FULL_RECT)
		rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rtl)

func on_pressed() -> void:
	on_pressed_input_assign.emit(self, input_key)

func update_by_event(new_key_event: InputEvent) -> void:
	text = get_button_text(new_key_event, tr)

static func get_button_text(input_event: InputEvent, tr_callable: Callable) -> String:
	if input_event == null:
		return ""
	
	#var txt: String = tr_callable.call(InputLocaleKeyLookup.get_locale_key_for(InputUtil.as_input_data(input_event)))
	var txt: String = ""
	if txt.length() > 10:
		txt = txt.substr(0, 10)
	return txt
