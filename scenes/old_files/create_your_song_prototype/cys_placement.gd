class_name Placement
extends Node2D

@export var wheel_scroll_base_speed: float = 5
@export var wheel_scroll_accel: float = 1.0
@export var max_mouse_x: float = 10000
@onready var pointer: Node2D = $Pointer

@onready var background: Sprite2D = $Background

@onready var added_sounds_parent: Node2D = $"../MovableLevel/AddedSounds"

const KICK_CYSSNIPPET = preload("uid://dcrnkxooyq5i4")
const M_1_CYSSNIPPET = preload("uid://b3s61uvjw0npg")


var is_active: bool = false

var scroll_strength: float = 0
var scroll_timer: float = 0

var current_place_soundsnippet: CYSSoundSnippet = null

func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	if !is_active:
		return
	
	if scroll_strength > 0.0:
		scroll_strength = lerp(scroll_strength, max(scroll_strength*0.6, 1.0), delta * 5)

func _input(event: InputEvent) -> void:
	if !is_active:
		return
		
	if event is InputEventMouse:
		#var iem: InputEventMouse = (event as InputEventMouse)
		pointer.global_position.x = clamp(get_global_mouse_position().x, 0, max_mouse_x)

	if event is InputEventMouseButton:
		var iemb: InputEventMouseButton = (event as InputEventMouseButton)
		
		if iemb.is_pressed():
			if iemb.button_index == MOUSE_BUTTON_WHEEL_UP:
				scroll_strength = lerp(scroll_strength, 50.0, 0.12)
				#print("scroll strength (r) ", scroll_strength)

				self.global_position.x = self.global_position.x + wheel_scroll_base_speed * scroll_strength

			if iemb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scroll_strength = lerp(scroll_strength, 50.0, 0.12)
				#print("scroll strength (l) ", scroll_strength)

				self.global_position.x = self.global_position.x - wheel_scroll_base_speed * scroll_strength

func set_active() -> void:
	is_active = true
	visible = true

func set_inactive() -> void:
	is_active = false
	visible = false


func set_snippet_type(sound_type: CYSSoundSnippet.SoundType) -> void:
	if is_instance_valid(current_place_soundsnippet):
		current_place_soundsnippet.queue_free()

	match sound_type:
		CYSSoundSnippet.SoundType.KICK:
			current_place_soundsnippet = KICK_CYSSNIPPET.instantiate()
			
		CYSSoundSnippet.SoundType.M1:
			current_place_soundsnippet = M_1_CYSSNIPPET.instantiate()
			
		CYSSoundSnippet.SoundType.M2:
			current_place_soundsnippet = M_1_CYSSNIPPET.instantiate()
			
	pointer.add_child(current_place_soundsnippet)	
	current_place_soundsnippet.set_placeable(true)
	current_place_soundsnippet.position = Vector2.ZERO

	current_place_soundsnippet.global_position = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var iemb: InputEventMouseButton = (event as InputEventMouseButton)
		if iemb.is_pressed() && iemb.button_index == MOUSE_BUTTON_LEFT:
			if current_place_soundsnippet.is_placeable():
				current_place_soundsnippet.set_placeable(false)
				current_place_soundsnippet.reparent(added_sounds_parent)
		
		if iemb.is_pressed() && iemb.button_index == MOUSE_BUTTON_RIGHT:
			for os: CYSSoundSnippet in current_place_soundsnippet.obstructing_snippets:
				os.queue_free()
