# We want some key-value way to hook up specific event triggers
# Probably "Midi track": "offset"
# This way we can send a signal at the given offset
class_name RhythmEvent
extends Resource
	
@export var trackname: StringName
@export var offset: float = 0.0
# Identifier is a unique identifier which can be used to cross reference
# an incoming signal so we know what we actually want to trigger
@export var identifier: StringName
