class_name RhythmTriggerEvent
extends Resource

var trackname: StringName
var offset: float = 0.0
var offset_beats: float = 0.0
var use_beats: bool = false
var identifier: StringName
var time: float = 0.0
var note: RhythmNote

var debug_color: Color

func _to_string() -> String:
	return "RhythmTriggerEvent - %s (%s | %.2f %.2f)" % [identifier, trackname, time, offset]
