class_name ResourceNote extends Resource

@export var start: float = 0.0
@export var duration: float = 0.0
@export var track_index: int = 0

func to_rhythm_note() -> RhythmNote:
	return RhythmNote.new(start, duration, 0, track_index)


static func to_rhythm_note_array(resource_notes: Array[ResourceNote]) -> Array[RhythmNote]:
	var rhythmnotes: Array[RhythmNote] = []
	for res_note: ResourceNote in resource_notes:
		rhythmnotes.append(res_note.to_rhythm_note())
		
	return rhythmnotes
