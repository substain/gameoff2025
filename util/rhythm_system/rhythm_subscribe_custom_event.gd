class_name RhythmSubscribeCustomEvent
extends Resource

@export var identifier: String
@export var time: float = 0.0
# TODO: Figure out how to handle beats when a tempo change happens...
@export var beats: int = 0
@export var use_beats: bool = false

@export var BEATS_NOT_IMPLEMENTED_YET: bool = true

@export_group("Debug")
@export var debug_color: Color = Color.CORAL
