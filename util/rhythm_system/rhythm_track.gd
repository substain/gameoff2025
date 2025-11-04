class_name RhythmTrack
extends RefCounted

var name: String = ""
var index: int = 0
var notes: Array[RhythmNote] = []

func _init(i: int, n: String) -> void:
	self.index = i
	self.name = n
