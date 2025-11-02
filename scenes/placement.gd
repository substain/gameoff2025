class_name Placement
extends Node2D

@onready var pointer: Sprite2D = $Pointer
@export var wheel_scroll_speed: float = 10
@onready var background: Sprite2D = $Background

var is_active: bool = false


func _ready() -> void:
	pass # Replace with function body.


func _process(_delta: float) -> void:
	if !is_active:
		return

func _input(event: InputEvent) -> void:
	if !is_active:
		return
		
	if event is InputEventMouse:
		var iem: InputEventMouse = (event as InputEventMouse)
		pointer.global_position.x = get_global_mouse_position().x

	if event is InputEventMouseButton:
		var iemb: InputEventMouseButton = (event as InputEventMouseButton)
		
		if iemb.is_pressed():
			if iemb.button_index == MOUSE_BUTTON_WHEEL_UP:
				self.global_position.x = self.global_position.x + wheel_scroll_speed			
			if iemb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				self.global_position.x = self.global_position.x - wheel_scroll_speed

func set_active() -> void:
	is_active = true
	visible = true

func set_inactive() -> void:
	is_active = false
	visible = false
