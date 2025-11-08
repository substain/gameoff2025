class_name RhythmEventCreator
extends Node

const LEAF_SCENE: PackedScene = preload("uid://lal43a7famlj")

const TELEGRAPH_EVENT_IDENTIFIER: String = "telegraph"
@export var telegraph_time_offset: float = 2.0
@export var leaf_spawn_offset: float = 10.0
@export var event_node_parent: Node2D
@export var zen_player_path_follow: ZenPlayerPathFollow

func create_leaf() -> void:
	var target_position: Vector2 = zen_player_path_follow.get_telegraphed_position(telegraph_time_offset)
	var leaf: Leaf = LEAF_SCENE.instantiate() as Leaf
	
	event_node_parent.add_child(leaf)
	leaf.global_position = target_position
	leaf.set_fall_time(telegraph_time_offset, true)
	leaf.start_falling()
	
func _on_rhythm_base_event_triggered(event: RhythmTriggerEvent, time: float) -> void:
	if event.identifier == TELEGRAPH_EVENT_IDENTIFIER:
		create_leaf()
