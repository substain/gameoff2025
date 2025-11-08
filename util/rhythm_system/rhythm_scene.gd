@tool
extends Control
class_name RhythmScene

signal parsing_finished(data: RhythmData)
signal preparing_debug_visualization_finished()
signal building_event_list_finished()
#signal ready() ist ja automatisch wenn alles fertig ist

# Note Hit greift bei tap sofort, bei Held erst wenn alles durch ist
# und der Spieler rechtzeitig wieder losgelassen hat
signal note_hit(track: RhythmTrack, note: RhythmNote)
signal note_missed(track: RhythmTrack, note: RhythmNote)
signal note_failed(track: RhythmTrack, note: RhythmNote)

signal event_triggered(event: RhythmTriggerEvent, time: float)

signal note_tap_hit(track: RhythmTrack, note: RhythmNote)
signal note_hold_start(track: RhythmTrack, note: RhythmNote)
signal note_hold_release(track: RhythmTrack, note: RhythmNote)

signal started_playing
signal stopped_playing
signal reset_progress

@export var scene_data: RhythmSceneData

@export_category("Debug")
@export_tool_button("Check Files") var check_action: Callable = check
@export_tool_button("Print Midi Tracks") var print_midi_tracks_action: Callable = print_midi_tracks

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var visualizer: RhythmVisualizer = $DebugVisualizer

var _next_event_index: int = 0
# var _is_running: bool = false

var _trigger_events: Array[RhythmTriggerEvent] = []
var _subscribed_events: Array[RhythmSubscribeNoteEvent] = []
var _rhythm_data: RhythmData

var _held_notes: Dictionary[RhythmTrack, RhythmNote] = {}
  
var _music_position: float = 0.0

func _ready() -> void:
	# Tool script macht sonst tool script sachen
	if Engine.is_editor_hint():
		return
	
	audio_stream_player.stream = scene_data.backing_track
	
	_rhythm_data = process_midi_file(scene_data.midi_file)
	parsing_finished.emit(_rhythm_data)
	
	build_event_list(_rhythm_data, scene_data.subscribed_events, scene_data.custom_events)
	building_event_list_finished.emit()
	
	visualizer.set_rhythm_data(_rhythm_data, scene_data.input_buffer_seconds, scene_data.note_tap_hold_threshold_seconds)
	preparing_debug_visualization_finished.emit()

func register_animation_for_track(event: RhythmSubscribeNoteEvent) -> void:
	_subscribed_events.append(event)
	# TODO: nicht vollständige events rausfiltern (aktuell wird das in build_event_list gemacht, das
	# kann aber ruhig schon hier passieren).
	# z.B: fehlender oder nicht passender trackname, fehlender identifier
	print("Registered event '%s' for track %s with %.2f offset" % [event.identifier, event.trackname, event.offset])

func _get_track_for_input(input_action: StringName) -> RhythmTrack:
	var track_name: StringName
	
	# NOTE: Theoretisch kann das hier auch ein Dictionary sein... aber so reichts ja
	match input_action:
		InputHandler.ACTION_A:
			track_name = scene_data.button_a_trackname
		InputHandler.ACTION_B:
			track_name = scene_data.button_b_trackname
		# TODO: Schauen wie man 2 Tasten gleichzeitig ordentlich detected...
		#"note_input_ab":
		#	track_name = scene_data.button_ab_trackname
		_:
			return null
			
	if track_name.is_empty():
		return null
		
	for track: RhythmTrack in _rhythm_data.tracks:
		if track.name == track_name:
			return track
			
	return null

# NOTE: Es kann beim neu laden vom level zu problemen kommen. Am besten sollte die ganze Szene neu geladen werden
# sodass immer frische "RhythmNote"-Objekte erstellt werden (diese haben nämlich einen internen state
# welcher bisher nicht zurückgesetzt wird).
# Ist nicht unmöglich das zu beheben, aber für den Jam sollte das reichen
# bzw ist der Aufwand nicht gaaaaaanz ohne und unnötig wenn man bescheid weiß :)

# TODO: Input buffer checken... ich glaube der müsste an mehreren stellen halbier werden
# weil +-.... muss man nochmal testen
# man kann beim lied den pitch runter drehen dann läuft das lied langsamer... vereinfacht das testen :)
func _get_hittable_note(track: RhythmTrack, current_time: float) -> RhythmNote:
	var input_buffer: float = scene_data.input_buffer_seconds
	
	for note: RhythmNote in track.notes:
		if note.is_hit:
			continue
		
		# Deckt tap + hold ab. Ggf muss man schauen ob das bei längeren tap notes
		# zu problemen kommen kann
		var start_hit_window: float = note.start - input_buffer
		var end_hit_window: float = note.start + note.duration + input_buffer
		
		# checke ob zeit innerhalb der gesamten Note
		# Dies ist auch wichtig, damit eine Note "gefailed" werden kann
		# Hier gibt es nämlich 2 Optionen:
		# a) man drückt gar nicht
		# b) man drückt zu spät/während die Note aktiv ist
		# Bei rhythm heaven ist das eigentlich egal, hier wird nur gezahlt WAS
		# man getroffen hat und nicht was nicht.... glaube ich
		if current_time >= start_hit_window and current_time <= end_hit_window:
			return note
			
		# early exit wenn die nächste Note zu weit in der Zukunft ist
		if note.start > current_time + input_buffer:
			break
			
	return null

func build_event_list(data: RhythmData, subscribed_events: Array[RhythmSubscribeNoteEvent], custom_events: Array[RhythmSubscribeCustomEvent]) -> void:
	for event: RhythmSubscribeNoteEvent in subscribed_events:
		register_animation_for_track(event)
	
	_trigger_events.clear()
	
	if not data:
		printerr("RhythmData is null. Cannot build event list.")
		return

	var tracks_by_name: Dictionary = {}
	for track: RhythmTrack in _rhythm_data.tracks:
		tracks_by_name[track.name] = track
	

	for mapping: RhythmSubscribeNoteEvent in _subscribed_events:
		var track_name: String = mapping.trackname
		var track_trigger_events: Array[RhythmTriggerEvent] = []
		
		if not tracks_by_name.has(track_name):
			printerr("trackname '%s' not found." % track_name)
			continue
			
		var track_object: RhythmTrack = tracks_by_name[track_name]
		
		# RhythmTriggerEvent für jede Note in dem Track anlegen
		for note: RhythmNote in track_object.notes:
			var offset_in_seconds: float = mapping.offset
			if mapping.use_beats:
				var beats: float = mapping.offset_beats
				
				var bps_at_note: float = _rhythm_data.get_bps_at_time(note.start)
			
				var beat_offset_in_seconds: float = beats / bps_at_note
				
				# TODO: Wir könnten auch Sekunden UND Beat offset gleichzeitig nutzen
				# hierfür +=
				offset_in_seconds = beat_offset_in_seconds
			
			var trigger_time: float = note.start + offset_in_seconds
			
			# Nur events berücksichtigen welche auch in der playtime des liedes sind
			# bzw. > 0.0 sekunden. Nach hinten raus kann es ja ruhig noch was animieren
			# (Wobei das nie triggern würde.... na mal schauen).
			if trigger_time >= 0:
				var rte: RhythmTriggerEvent = RhythmTriggerEvent.new()
				rte.time = trigger_time
				rte.offset = offset_in_seconds
				rte.offset_beats = mapping.offset_beats
				rte.use_beats = mapping.use_beats
				rte.identifier = mapping.identifier
				rte.note = note
				rte.trackname = track_object.name
				rte.debug_color = mapping.debug_color
				_trigger_events.append(rte)
				track_trigger_events.append(rte)
				
		track_trigger_events.sort_custom(func(a: RhythmTriggerEvent, b: RhythmTriggerEvent) -> bool: return a.time < b.time)
		track_object.events[mapping.identifier] = track_trigger_events

	data.custom_events.clear()

	for custom_event: RhythmSubscribeCustomEvent in custom_events:
		var time_in_seconds: float = custom_event.time
		#if mapping.use_beats:
		#		var beats: float = mapping.offset_beats
		#		
		#		var bps_at_note: float = _rhythm_data.get_bps_at_time(note.start)
		#	
		#		var beat_offset_in_seconds: float = beats / bps_at_note
		#		
		#		# TODO: Wir könnten auch Sekunden UND Beat offset gleichzeitig nutzen
		#		# hierfür +=
		#		offset_in_seconds = beat_offset_in_seconds
			
		var trigger_time: float = time_in_seconds
			
		# Nur events berücksichtigen welche auch in der playtime des liedes sind
		# bzw. > 0.0 sekunden. Nach hinten raus kann es ja ruhig noch was animieren
		# (Wobei das nie triggern würde.... na mal schauen).
		if trigger_time >= 0:
			var rte: RhythmTriggerEvent = RhythmTriggerEvent.new()
			rte.time = trigger_time
			rte.offset = 0.0
			rte.offset_beats = 0.0
			rte.use_beats = false
			rte.identifier = custom_event.identifier
			rte.note = null
			rte.trackname = ""
			rte.debug_color = custom_event.debug_color
			_trigger_events.append(rte)
			data.custom_events.append(rte)
			#track_trigger_events.append(rte)

	data.custom_events.sort_custom(func(a: RhythmTriggerEvent, b: RhythmTriggerEvent) -> bool: return a.time < b.time)

	_trigger_events.sort_custom(func(a: RhythmTriggerEvent, b: RhythmTriggerEvent) -> bool: return a.time < b.time)
	
	#print(_trigger_events)
	print("Built %d total trigger events." % _trigger_events.size())
	
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
	var tracknames: Array[StringName] = []

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
			
		var event_trackname: StringName = keys_dict[key]
			
		if event_trackname not in tracknames:
			printerr("Key '%s' not found in midi tracknames! Typo? Maybe the midi changed?" % key)
			all_good = false
			#return
			
	for event: RhythmSubscribeNoteEvent in scene_data.subscribed_events:
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
	audio_stream_player.play(0.0)
	reset_progress.emit()
	started_playing.emit()

func set_paused(is_paused_new: bool) -> void:
	if is_paused_new:
		_music_position = audio_stream_player.get_playback_position()
		audio_stream_player.stop()
		stopped_playing.emit()
	else:
		audio_stream_player.play(_music_position)
		started_playing.emit()
	
func stop() -> void:
	_music_position = 0.0
	audio_stream_player.stop()	
	stopped_playing.emit()
	reset_progress.emit()

func set_ui_visible(is_ui_visible_new: bool) -> void:
	visualizer.visible = is_ui_visible_new

func _input(event: InputEvent) -> void:
	var current_time: float = audio_stream_player.get_playback_position()
	var input_buffer: float = scene_data.input_buffer_seconds
	var hold_threshold: float = scene_data.note_tap_hold_threshold_seconds
	
	# TODO: Globale Konstante für die Input-Namen verwenden
	var rhythm_actions: Array[StringName] = [InputHandler.ACTION_A, InputHandler.ACTION_B, InputHandler.ACTION_C] # note_input_ab
	
	# Checkt alle Inputs (A, B, AB) durch
	for input_action: StringName in rhythm_actions:
		var is_pressed: bool = event.is_action_pressed(input_action)
		var is_released: bool = event.is_action_released(input_action)
		
		if not is_pressed and not is_released:
			continue
			
		var track: RhythmTrack = _get_track_for_input(input_action)
		if not track:
			continue

		var track_name: StringName = track.name
		
		if is_pressed:
			var hittable_note: RhythmNote = _get_hittable_note(track, current_time)

			if hittable_note:
				hittable_note.status = RhythmNote.STATUS.NONE
				
				# Check for Tap/Start window (+- buffer around note.start)
				var press_window_start: float = hittable_note.start - input_buffer
				var press_window_end: float = hittable_note.start + input_buffer
				
				if current_time >= press_window_start and current_time <= press_window_end:
					hittable_note.is_hit = true
					
					if hittable_note.duration < hold_threshold:
						print("TAP NOTE HIT!")
						hittable_note.status = RhythmNote.STATUS.COMPLETE
						note_tap_hit.emit(track, hittable_note)
						note_hit.emit(track, hittable_note)
						
					else:
						print("HOLD NOTE STARTED")
						hittable_note.status = RhythmNote.STATUS.HELD
						_held_notes[track] = hittable_note
						note_hold_start.emit(track, hittable_note)
					
					return 
			
			print("Input Missed/Early on press: ", track_name)
			
		# input losgelassen, für held notes
		elif is_released:
			if _held_notes.has(track):
				var held_note: RhythmNote = _held_notes[track]
				var release_hit_window_start: float = held_note.start + held_note.duration - input_buffer
				var release_hit_window_end: float = held_note.start + held_note.duration + input_buffer
				
				_held_notes.erase(track_name)

				# CÜberprüfe ob innerhalb der input_buffer losgelassen wurde
				if current_time >= release_hit_window_start and current_time <= release_hit_window_end:
					held_note.status = RhythmNote.STATUS.COMPLETE
					print("HOLD NOTE FINISHED")
					note_hold_release.emit(track, held_note)
					note_hit.emit(track, held_note)
				else:
					# held note zu früh oder zu spät losgelassen
					held_note.status = RhythmNote.STATUS.FAILED
					note_failed.emit(track, held_note)
					print("Hold Note Failure (Release Timing) on track: ", track_name)
	
	# Zum testen, leertaste/enter -> start
	if event.is_action_pressed(InputHandler.DEBUG_START_TRACK):
		start()

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	var current_time: float = audio_stream_player.get_playback_position() # + AudioServer.get_time_since_last_mix()
	visualizer.current_seconds = current_time

	while _next_event_index < _trigger_events.size() and _trigger_events[_next_event_index].time <= current_time:
		var event: RhythmTriggerEvent = _trigger_events[_next_event_index]
		event_triggered.emit(event, current_time)
		print("Emitting ", event)
		_next_event_index = _next_event_index + 1

	# checken ob eine Note gar nicht gedrückt wurde
	var input_buffer: float = scene_data.input_buffer_seconds
	
	for track: RhythmTrack in _rhythm_data.tracks:
		var track_name: StringName = track.name
		
		# filtere nach Noten welche noch nicht getroffen wurden
		# und welche ihr "treffer Zeitfenster" verpasst haben
		for note: RhythmNote in track.notes: 
			if note.status != RhythmNote.STATUS.NONE:
				# ist bereits getroffen, oder wird gehalten
				# oder ist bereits verpasst worden
				continue
			
			var note_miss_time: float = note.start + input_buffer
			
			# Anfang von tap + hold notes komplett verpasst
			if current_time > note_miss_time:
				note.status = RhythmNote.STATUS.MISSED 
				
				# Nicht ganz sicher ob der check so stimmt
				# Checkt ob eine ggf. gehaltene Note verpasst wurde...
				# Aber bin noch nicht sicher ob get_next_hittable_note() so richtig ist..
				 
				if _held_notes.has(track) and _held_notes[track] == note:
					_held_notes.erase(track)
					
					
				note_missed.emit(track, note)
				print("Note Missed (Past window): ", track_name)
				   
			# wenn Note zu weit in der Zukunft, early exit
			# ggf. noch input buffer drauf rechnen?
			elif note.start > current_time:
				break

func _process(_delta: float) -> void:
	# TODO: Maybe update the debug visualization in process?
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

	var tempo_map_ticks: Array = _build_tempo_map(parser)

	var rhythm_data: RhythmData = RhythmData.new()

	for idx: int in parser.tracks.size():
		var track_parser: MidiFileParser.Track = parser.tracks[idx]

		# Trackname auslesen
		var track_name: String = "Track %d" % (idx + 1)
		for event: MidiFileParser.Event in track_parser.meta:
			if (event as MidiFileParser.Meta).type == MidiFileParser.Meta.Type.TRACK_NAME:
				track_name = (event as MidiFileParser.Meta).bytes.get_string_from_utf8()
				break

		var rhythm_track: RhythmTrack = RhythmTrack.new(idx, track_name)

		rhythm_track.notes = _process_track_events(track_parser.events, tempo_map_ticks, idx)
		rhythm_data.tracks.append(rhythm_track)

	var tempo_map_seconds: Array[RhythmTempoMapEntry] = []
	for entry: Dictionary in tempo_map_ticks:
		var entry_time_sec: float = _ticks_to_seconds(entry.ticks, tempo_map_ticks)
		
		tempo_map_seconds.append(RhythmTempoMapEntry.new(entry_time_sec, entry.bpm))
		
	rhythm_data.tempo_map = tempo_map_seconds
		
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
				var bpm: float = 60000000.0 / meta_event.value
				if meta_event.type == MidiFileParser.Meta.Type.SET_TEMPO:
					tempo_map.append(
						{
							"ticks": meta_event.absolute_ticks,
							"ms_per_tick": meta_event.ms_per_tick,
							"bpm": bpm
						}
					)

	# Sortieren und doppelte entfernen
	tempo_map.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.ticks < b.ticks)

	var unique_tempo_map: Array = []
	if tempo_map.is_empty() || tempo_map[0].ticks > 0:
		# Nutze Standardtempo falls bei tick 0 nicht direkt eines gesetzt wird
		var default_ms_per_tick: float = 60000.0 / (120.0 * float(parser.header.time_division))
		unique_tempo_map.append({"ticks": 0, "ms_per_tick": default_ms_per_tick, "bpm": 120.0})

	var last_tick: int = -1
	for entry: Dictionary in tempo_map:
		if entry.ticks == last_tick:
			# Bei mehreren changes im selben Tick, behalte "letztes" event
			unique_tempo_map[-1] = entry 
		else:
			unique_tempo_map.append(entry)
			last_tick = entry.ticks

	return unique_tempo_map

func get_beat_duration_in_seconds(beats: float = 1.0) -> float:
	return 1.0 / _rhythm_data.get_bps_at_time(audio_stream_player.get_playback_position()) * beats

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
