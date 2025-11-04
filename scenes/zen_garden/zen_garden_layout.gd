@tool
class_name ZenGardenLayout
extends Node

@export var notes: Array[NoteDummy] = []
@export var stop_generating_on_illegal_note: bool = true
@export var min_note_time_difference: float = 0.2

@export_tool_button("generate") var generate_btn: Callable = do_generate

func _ready() -> void:
	pass

func do_generate() -> void:
	validate_notes()

func validate_notes() -> bool:
	print("validating notes...")
	notes.sort_custom(sort_by_start_time)
	var notes_copy: Array[NoteDummy] = notes.duplicate(false)
	var current_note_times: Dictionary[int, float] = {}
	for note: NoteDummy in notes:
		if note == null:
			push_warning("notes contains a null item :/")
			continue
	
		if note is NoteHoldDummy:
			print("note hold: ", note, ":[",note.note_position,"] start: ", note.start_time_offset, ", end: ", (note as NoteHoldDummy).end_time_offset)
		else:
			print("note: ", note, ":[",note.note_position,"] start: ", note.start_time_offset)
			

		if note.start_time_offset < 0:
			var stop_generation: bool = on_found_invalid_note(notes_copy, note, "start-offset is below 0 for a Note at position " + str(note.note_position))
			if stop_generation:
				return false
			
		if note is NoteHoldDummy:
			var end_time: float = (note as NoteHoldDummy).end_time_offset
			if end_time < 0.0:
				var stop_generation: bool = on_found_invalid_note(notes_copy, note, "end time ("+ str(end_time) + ") is below 0 for a NoteHold at position " + str(note.note_position))
				if stop_generation:
					return false
			
			if end_time < note.start_time_offset:
				var stop_generation: bool = on_found_invalid_note(notes_copy, note, "end time ("+ str(end_time) + ") is below start time ("+str(note.start_time_offset)+ ") for a NoteHold at position " + str(note.note_position))
				if stop_generation:
					return false
			
		if !current_note_times.has(note.note_position):
			current_note_times[note.note_position] = note.start_time_offset
		else:
			var time_diff: float = note.start_time_offset - current_note_times[note.note_position]
			if time_diff < min_note_time_difference:
				var stop_generation: bool = on_found_invalid_note(notes_copy, note, "interval to the previous time ("+ str(time_diff) + ") is below minimum ("+str(min_note_time_difference)+ ") for note position " + str(note.note_position))
				if stop_generation:
					return false
				
			var end_time: float = note.start_time_offset
			if note is NoteHoldDummy:
				end_time = (note as NoteHoldDummy).end_time_offset
				
			current_note_times[note.note_position] = end_time
				
	print("array: ", notes_copy)
	return true
	
func on_found_invalid_note(notes_copy: Array[NoteDummy], note: NoteDummy, reason: String) -> bool:
	var note_index: int = notes_copy.find(note)
	var action_str: String = "stopping the generation." if stop_generating_on_illegal_note else "ignoring this note."
	push_error("found an invalid note at index: ", note_index, ", reason: ", reason, ". => ", action_str)
	
	if stop_generating_on_illegal_note:
		return true
		
	notes_copy.remove_at(note_index)
	return false
	
func sort_by_start_time(a: NoteDummy, b: NoteDummy) -> bool:
	return a.start_time_offset < b.start_time_offset
