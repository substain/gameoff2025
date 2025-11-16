class_name RhythmTempoMapEntry
extends RefCounted

var time: float = 0.0
# 120 bpm ist default bei midi
var bpm: float = 120.0

func _init(t: float, b: float) -> void:
	time = t
	bpm = b
