class_name RhythmSceneData
extends Resource

@export_group("Music")
@export var backing_track: AudioStream
@export_file var midi_file: String

@export_group("Input")
@export var button_a_trackname: StringName
@export var button_b_trackname: StringName
@export var button_ab_trackname: StringName

@export_subgroup("Timing")
@export var input_buffer_seconds: float = 0.1
# NOTE: Hiermit wird entschieden ob eine Note gehalten oder nur kurz gedrückt werden muss
# Alles was kürzer ist ist nur ein "Tap", alles darüber ein "Hold"
@export var note_tap_hold_threshold_seconds: float = 0.5

@export_subgroup("Events")
@export var subscribed_events: Array[RhythmSubscribeEvent] = []
