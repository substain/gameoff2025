@tool
class_name ZenGardenLayout
extends Node

@export var notes: Array[ResourceNote] = []
@export var stop_generating_on_illegal_note: bool = true
@export var min_note_time_difference: float = 0.2

@export_tool_button("generate") var generate_btn: Callable = do_generate

func _ready() -> void:
	pass

func do_generate() -> void:
	var notes_to_use: Array[RhythmNote] = ResourceNote.to_rhythm_note_array(notes)
	var cleaned_notes: Array[RhythmNote] = MidiValidator.validate_notes(notes_to_use, stop_generating_on_illegal_note, min_note_time_difference)
