# We want some key-value way to hook up specific event triggers
# Probably "Midi track": "offset"
# This way we can send a signal at the given offset
class_name RhythmSubscribeNoteEvent
extends Resource
	
@export var trackname: StringName
@export var offset: float = 0.0

@export var offset_beats: int = 0
@export var use_beats: bool = false
# TODO: We should provide a way to scale animations for different bpm
# so these animations will always fit
# We can use 1 second as a base animation duration and then calculate how
# long a given beat currently is.
# But this will probably happen in the rhythmbase script (a function to return scaled time)

# Identifier is a unique identifier which can be used to cross reference
# an incoming signal so we know what we actually want to trigger
@export var identifier: StringName

@export_group("Debug")
@export var debug_color: Color = Color.CORAL
