class_name RhythmEventCreator
extends Node

const FALLING_OBJECT: PackedScene = preload("res://scenes/zen_garden/falling_object.tscn")

const TELEGRAPH_DRUM_EVENT_ID: String = "telegraph_drums"
const TELEGRAPH_THROAT_EVENT_ID: String = "telegraph_throat"
@export var leaf_spawn_offset: float = 10.0
@export var event_node_parent: Node2D
@export var zen_player_path_follow: ZenPlayerPathFollow
@export var singing_monk: SingingMonk

## fall_objects are removed when they are destroyed / on the ground (not when they are freed)
var current_fall_objects: Dictionary[String, FallingObject] = {}

func create_leaf(event: RhythmTriggerEvent) -> void:
	var target_position: Vector2 = zen_player_path_follow.get_telegraphed_position(-event.offset)
	var fall_object: FallingObject = FALLING_OBJECT.instantiate() as FallingObject
	var fo_id: String = event.note.get_combined_id()

	fall_object.global_position = target_position
	event_node_parent.add_child(fall_object)
	fall_object.set_fall_time(-event.offset, true)
	fall_object.start_falling()
	fall_object.on_remove.connect(on_free_falling_object.bind(fo_id))
	current_fall_objects[fo_id] = fall_object

func _on_rhythm_base_event_triggered(event: RhythmTriggerEvent, _time: float) -> void:
	if event.identifier == TELEGRAPH_DRUM_EVENT_ID:
		create_leaf(event)
	elif event.identifier == TELEGRAPH_THROAT_EVENT_ID:
		singing_monk.start_telegraph(event)

func on_free_falling_object(leaf_id: String) -> void:
	current_fall_objects.erase(leaf_id)

func get_falling_object_by_note(note: RhythmNote) -> FallingObject:
	var fo_id: String = note.get_combined_id()
	if !current_fall_objects.has(fo_id):
		push_warning("could not find falling object for requested event: ", note)
		return null
		
	var res: FallingObject = current_fall_objects[fo_id]
	if !is_instance_valid(res):
		push_warning("invalid falling object instance found at key ", fo_id, " for ", note)
		
	return res
	
