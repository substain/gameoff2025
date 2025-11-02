class_name SoundSnippet 
extends StaticBody2D

enum SoundType{
	KICK,
	CLAP,
	M1,
	M2,
	S1,
	S2
}

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var sound_type: SoundType

var obstructing_snippets: Array[SoundSnippet] = []

var for_placement: bool = false

var is_active: bool = false

func _ready() -> void:
	set_inactive()

func add_obstructing_snippet(other_snippet: SoundSnippet) -> void:
	if obstructing_snippets.has(other_snippet):
		return
		
	obstructing_snippets.append(other_snippet)
	validate()
	
func remove_obstructing_snipped(other_snippet: SoundSnippet) -> void:
	if !obstructing_snippets.has(other_snippet):
		return

	obstructing_snippets.erase(other_snippet)
	validate()

func validate() -> void:
	pass
	
	
func is_placeable() -> bool:
	return obstructing_snippets.is_empty()
	
func play() -> void:
	if !is_active:
		return
		
	set_inactive()
	
	match sound_type:
		SoundType.KICK:
			Globals.sound_manager.play_kick()
		SoundType.CLAP:
			Globals.sound_manager.play_clap()
		SoundType.M1:
			Globals.sound_manager.play_m1()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if !is_instance_valid(body):
		return
		
	if body is Player:
		play()
		return
		
	if body is SoundSnippet:
		(body as SoundSnippet).add_obstructing_snippet(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if !is_instance_valid(body):
		return

	if body is SoundSnippet:
		(body as SoundSnippet).remove_obstructing_snipped(self)

func set_active() -> void:
	is_active = true

func set_inactive() -> void:
	is_active = false

func set_placeable(is_placeable: bool) -> void:
	for_placement = is_placeable
	collision_shape_2d.disabled = is_placeable
