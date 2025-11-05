class_name MidiValidator
extends Object

const STOP_ON_BAD_NOTE_DEFAULT: bool = true
const MIN_NOTE_TIME_DIFF_DEFAULT: float = 0.2

static func validate_notes(notes_to_validate: Array[RhythmNote], 
	stop_on_bad_note: bool = STOP_ON_BAD_NOTE_DEFAULT,
	min_note_time_diff: float = MIN_NOTE_TIME_DIFF_DEFAULT) -> Array[RhythmNote]:
		
	print("validating notes...")
	notes_to_validate.sort_custom(sort_by_start_time)
	var notes_copy: Array[RhythmNote] = notes_to_validate.duplicate(false)
	var current_note_times: Dictionary[int, float] = {}
	for note: RhythmNote in notes_to_validate:
		if note == null:
			push_warning("notes contains a null item :/")
			continue
	
		if is_note_to_hold(note):
			print("holdnote: ", note, ":[",note.track_index,"] start: ", note.start, ", duration: ", note.duration)
		else:
			print("note: ", note, ":[",note.track_index,"] start: ", note.start)
			

		if note.start < 0:
			var stop_generation: bool = on_found_invalid_note(notes_copy, note, "start-offset is below 0 for a Note at position " + str(note.track_index), stop_on_bad_note)
			if stop_generation:
				return []
			
		if is_note_to_hold(note):
			var end_time: float = note.end_time_offset
			if end_time < 0.0:
				var stop_generation: bool = on_found_invalid_note(notes_copy, note, "end time ("+ str(end_time) + ") is below 0 for a NoteHold at position " + str(note.track_index), stop_on_bad_note)
				if stop_generation:
					return []
			
			if end_time < note.start:
				var stop_generation: bool = on_found_invalid_note(notes_copy, note, "end time ("+ str(end_time) + ") is below start time ("+str(note.start)+ ") for a NoteHold at position " + str(note.track_index), stop_on_bad_note)
				if stop_generation:
					return []
			
		if !current_note_times.has(note.track_index):
			current_note_times[note.track_index] = note.start
		else:
			var time_diff: float = note.start - current_note_times[note.track_index]
			if time_diff < min_note_time_diff:
				var stop_generation: bool = on_found_invalid_note(notes_copy, note, "interval to the previous time ("+ str(time_diff) + ") is below minimum ("+str(min_note_time_diff)+ ") for note position " + str(note.track_index), stop_on_bad_note)
				if stop_generation:
					return []
				
			var end_time: float = note.start
			if is_note_to_hold(note):
				end_time = note.start + note.duration
				
			current_note_times[note.track_index] = end_time
	
	print("array: ", notes_copy)
	if notes_copy.size() == 0:
		push_warning("The result array does not contain any notes.")
				
	return notes_copy
	
static func on_found_invalid_note(notes_copy: Array[RhythmNote], note: RhythmNote, reason: String, stop_on_bad_note: bool) -> bool:
	var note_index: int = notes_copy.find(note)
	var action_str: String = "stopping the generation." if stop_on_bad_note else "ignoring this note."
	push_error("found an invalid note at index: ", note_index, ", reason: ", reason, ". => ", action_str)
	
	if stop_on_bad_note:
		return true
		
	notes_copy.remove_at(note_index)
	return false
	
static func is_note_to_hold(note: RhythmNote) -> bool:
	return note.duration > 0.3
	
static func sort_by_start_time(a: RhythmNote, b: RhythmNote) -> bool:
	return a.start < b.start
