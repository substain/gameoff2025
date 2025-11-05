@tool
extends Control
class_name RhythmScene

@warning_ignore_start("unused_signal")
signal parsing_finished(data: RhythmData)
signal note_hit(track: RhythmTrack)
signal note_failed(track: RhythmTrack)
signal note_event(track: RhythmTrack) # für anims uns krams?
@warning_ignore_restore("unused_signal")
@export var scene_data: RhythmSceneData

@export_category("Debug")
@export_tool_button("Check Files") var check_action: Callable = check
@export_tool_button("Print Midi Tracks") var print_midi_tracks_action: Callable = print_midi_tracks

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var visualizer: RhythmVisualizer = $Visualizer

func _ready() -> void:
	audio_stream_player.stream = scene_data.backing_track
	var data: RhythmData = process_midi_file(scene_data.midi_file)
	visualizer.set_rhythm_data(data, scene_data.input_buffer_seconds, scene_data.note_tap_hold_threshold_seconds)

func check() -> void:
	var all_good: bool = true
	print("Checking....")
	if scene_data == null:
		printerr("scene_data null. Aborting")
		return
		
	if scene_data.backing_track == null:
		printerr("scene_data.backing_track null. Aborting")
		return
		
	if scene_data.midi_file == null or scene_data.midi_file.is_empty():
		printerr("scene_data.midi_file not set. Aborting")
		return

	# Check Input Tracknames, for this we would need to parse the midi
	# and check if these tracks even exist
	var tracknames: Array[String] = []

	var data: RhythmData = process_midi_file(scene_data.midi_file)
	for track: RhythmTrack in data.tracks:
		#print(track.name)
		tracknames.push_back(track.name)
		
	var keys_dict: Dictionary[StringName, StringName] = {
		&"Button A Trackname": scene_data.button_a_trackname,
		&"Button B Trackname": scene_data.button_b_trackname,
		&"Button AB Trackname": scene_data.button_ab_trackname
	}
		
	for key: StringName in keys_dict:
		if keys_dict[key].is_empty():
			print_rich("[color=yellow][b]WARNING: Input for key '%s' is empty. If this is intentional (for example if the level does not make use of this button) you can ignore this warning.[/b][/color]" % key)
			#all_good = false
			continue
			
		if key not in tracknames:
			printerr("Key '%s' not found in midi tracknames! Typo? Maybe the midi changed?" % key)
			all_good = false
			#return
			
	for event: RhythmEvent in scene_data.subscribed_events:
		if event == null:
			printerr("Subscribed Events contains an empty resource. Please fix!")
			all_good = false
			continue
		
		if event.identifier.is_empty():
			printerr("Event has no identifier set! This event will never be called: Trackname: %s, Offset: %.2f" % [event.trackname, event.offset])
			all_good = false
			continue
		
		if event.trackname.is_empty():
			printerr("WARNING: Event with identifier '%s' has no trackname set! This event will never be triggered." % event.identifier)
			all_good = false
			continue
			
		if event.trackname not in tracknames:
			printerr("Trackname '%s' for Event '%s' not found in midi tracknames! Typo? Maybe the midi changed?" % [event.trackname, event.identifier])
			all_good = false
			
	if scene_data.subscribed_events.is_empty():
		print_rich("[color=yellow][b]WARNING: No subscribed events provided. If this is intentional you can ignore this warning.[/b][/color]")
		
	if not all_good:
		printerr("There were errors. Please check above!")
		return
		
	print_rich("[color=green][b]Everything looks good!")
	
func print_midi_tracks() -> void:
	if scene_data == null or scene_data.midi_file == null or scene_data.midi_file.is_empty():
		printerr("No midi file set. Check if scene data is set and the midi file path is correct")
		return
		
	var tracknames: Array[String] = []
		
	# TODO: Parse midi, get track names
	var data: RhythmData = process_midi_file(scene_data.midi_file)
	for track: RhythmTrack in data.tracks:
		#print(track.name)
		tracknames.push_back(track.name)
	
	print("Midi Tracknames:")
	var idx: int = 0
	for track: String in tracknames:
		print("%d: %s" % [idx, track])
		idx = idx + 1
		
	pass

func start() -> void:
	pass
	
func pause() -> void:
	pass
	
func stop() -> void:
	pass

func _input(event: InputEvent) -> void:
	pass
	if event.is_action_pressed("ui_accept"):
		audio_stream_player.play()

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	var time: float = audio_stream_player.get_playback_position() # + AudioServer.get_time_since_last_mix()
	visualizer.current_seconds = time
	
func is_within_note_buffer() -> void:
	pass
	
func process_midi_file(path: String) -> RhythmData:
	var parser: MidiFileParser = MidiFileParser.load_file(path)
	if not parser:
		printerr("MidiProcessor: Could not load file: %s" % path)
		return null

	var ppq: float = float(parser.header.time_division)
	if ppq <= 0.0:
		printerr("MidiProcessor: Invalid or zero PPQ.")
		return null

	var tempo_map: Array = _build_tempo_map(parser)

	var rhythm_data: RhythmData = RhythmData.new()

	for idx: int in parser.tracks.size():
		var track_parser: MidiFileParser.Track = parser.tracks[idx]

		# Determine the track's name
		var track_name: String = "Track %d" % (idx + 1)
		for event: MidiFileParser.Event in track_parser.meta:
			if (event as MidiFileParser.Meta).type == MidiFileParser.Meta.Type.TRACK_NAME:
				track_name = (event as MidiFileParser.Meta).bytes.get_string_from_utf8()
				break

		var rhythm_track: RhythmTrack = RhythmTrack.new(idx, track_name)

		rhythm_track.notes = _process_track_events(track_parser.events, tempo_map, idx)
		rhythm_data.tracks.append(rhythm_track)

	return rhythm_data


func _process_track_events(events: Array, tempo_map: Array, track_index: int) -> Array[RhythmNote]:
	var finished_notes: Array[RhythmNote] = []
	var open_notes: Dictionary = {}

	for event: MidiFileParser.Event in events:
		if event.event_type != MidiFileParser.Event.EventType.MIDI:
			continue

		# Keine Ahnung wie ich hier die Warnungen ordentlich wegbekomme...
		@warning_ignore_start("unsafe_property_access")
		var midi_event: MidiFileParser.Event = event
		var note_num: int = midi_event.param1
		var velocity: int = midi_event.param2

		var event_time_sec: float = _ticks_to_seconds(midi_event.absolute_ticks, tempo_map)

		var is_note_on: bool = midi_event.status == MidiFileParser.Midi.Status.NOTE_ON and velocity > 0
		var is_note_off: bool = (
			midi_event.status == MidiFileParser.Midi.Status.NOTE_OFF
			or (midi_event.status == MidiFileParser.Midi.Status.NOTE_ON and velocity == 0)
		)
		@warning_ignore_restore("unsafe_property_access")

		if is_note_on:
			if open_notes.has(note_num):
				_close_note(note_num, open_notes.get(note_num) as float, event_time_sec, finished_notes, track_index)
				open_notes.erase(note_num)
				
			open_notes[note_num] = event_time_sec

		elif is_note_off:
			if open_notes.has(note_num):
				var start_sec: float = open_notes.get(note_num)
				open_notes.erase(note_num)
				_close_note(note_num, start_sec, event_time_sec, finished_notes, track_index)

	return finished_notes

func _close_note(note_num: int, start_sec: float, end_sec: float, output_array: Array, track_index: int) -> void:
	var duration: float = end_sec - start_sec
	
	# Check damit nicht durch 0 geteilt wird (weiß nicht ob das im midi standard erlaubt ist Noten 
	# mit länge 0 zu haben.... aber je nach Rundungsfehlern hier kann das trotzdem passieren)
	if duration <= 0:
		duration = 0.001

	var note_obj: RhythmNote = RhythmNote.new(start_sec, duration, note_num, track_index)
	output_array.append(note_obj)


# Liste mit allen Tempo-Wechseln in der Datei. Zur korrekten Berechnung der absoluten Noten-Zeiten
func _build_tempo_map(parser: MidiFileParser) -> Array:
	var tempo_map: Array = []

	for track: MidiFileParser.Track in parser.tracks:
		for event: MidiFileParser.Event in track.events:
			if event.event_type == MidiFileParser.Event.EventType.META:
				var meta_event: MidiFileParser.Meta = event as MidiFileParser.Meta

				if meta_event.type == MidiFileParser.Meta.Type.SET_TEMPO:
					tempo_map.append(
						{"ticks": meta_event.absolute_ticks, "ms_per_tick": meta_event.ms_per_tick}
					)

	# Sortieren und doppelte entfernen
	tempo_map.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.ticks < b.ticks)

	var unique_tempo_map: Array = []
	if tempo_map.is_empty() || tempo_map[0].ticks > 0:
		# Nutze Standardtempo falls bei tick 0 nicht direkt eines gesetzt wird
		var default_ms_per_tick: float = 60000.0 / (120.0 * float(parser.header.time_division))
		unique_tempo_map.append({"ticks": 0, "ms_per_tick": default_ms_per_tick})

	var last_tick: int = -1
	for entry: Dictionary in tempo_map:
		if entry.ticks == last_tick:
			# Bei mehreren changes im selben Tick, behalte "letztes" event
			unique_tempo_map[-1] = entry 
		else:
			unique_tempo_map.append(entry)
			last_tick = entry.ticks

	return unique_tempo_map


func _ticks_to_seconds(absolute_ticks: int, tempo_map: Array) -> float:
	var current_time_ms: float = 0.0
	var last_tempo_tick: int = 0
	var current_ms_per_tick: float = tempo_map[0].ms_per_tick 

	for tempo_event: Dictionary in tempo_map:
		if absolute_ticks <= tempo_event.ticks:
			break

		var ticks_in_segment: int = tempo_event.ticks - last_tempo_tick
		current_time_ms += ticks_in_segment * current_ms_per_tick

		last_tempo_tick = tempo_event.ticks
		current_ms_per_tick = tempo_event.ms_per_tick

	var remaining_ticks: int = absolute_ticks - last_tempo_tick
	current_time_ms += remaining_ticks * current_ms_per_tick

	return current_time_ms / 1000.0
