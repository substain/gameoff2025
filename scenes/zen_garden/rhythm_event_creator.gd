class_name RhythmEventCreator
extends Node

const LEAF_SCENE: PackedScene = preload("uid://lal43a7famlj")

const TELEGRAPH_EVENT_IDENTIFIER: String = "telegraph"
@export var telegraph_time_offset: float = 2.0
@export var leaf_spawn_offset: float = 10.0
@export var event_node_parent: Node2D
@export var zen_player_path_follow: ZenPlayerPathFollow

## leaves are removed when they are destroyed / on the ground (not when they are freed)
var current_leaves: Dictionary[String, Leaf] = {}

func create_leaf(event: RhythmTriggerEvent) -> void:
	var target_position: Vector2 = zen_player_path_follow.get_telegraphed_position(telegraph_time_offset)
	var leaf: Leaf = LEAF_SCENE.instantiate() as Leaf
	var leaf_id: String = event.note.get_combined_id()

	leaf.global_position = target_position
	event_node_parent.add_child(leaf)
	leaf.set_fall_time(telegraph_time_offset, true)
	leaf.start_falling()
	leaf.on_remove.connect(on_free_leaf.bind(leaf_id))
	current_leaves[leaf_id] = leaf

func _on_rhythm_base_event_triggered(event: RhythmTriggerEvent, _time: float) -> void:
	if event.identifier == TELEGRAPH_EVENT_IDENTIFIER:
		create_leaf(event)

func on_free_leaf(leaf_id: String) -> void:
	current_leaves.erase(leaf_id)

func get_leaf_by_note(note: RhythmNote) -> Leaf:
	var leaf_id: String = note.get_combined_id()
	if !current_leaves.has(leaf_id):
		push_warning("could not find leaf for requested event: ", note)
		return null
		
	var res: Leaf = current_leaves[leaf_id]
	if !is_instance_valid(res):
		push_warning("invalid leaf instance found at key ", leaf_id, " for ", note)
		
	return res
	
