class_name RhythmNote
extends RefCounted
   
var start: float = 0.0
var duration: float = 0.0
var note_number: int = 0
var track_index: int = 0

# Runtime stuff
var is_hit: bool = false
var status: STATUS = STATUS.NONE

enum STATUS {
	NONE,
	HELD,
	COMPLETE,
	MISSED,
	FAILED
}

func _init(s: float, d: float, n: int, t: int) -> void:
	self.start = s
	self.duration = d
	self.note_number = n
	self.track_index = t
	
func get_combined_id() -> String:
	return "T"+str(track_index)+"_S"+str(start)
