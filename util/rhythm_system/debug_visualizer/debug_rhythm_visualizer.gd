class_name RhythmVisualizer
extends Control

var data: RhythmData
var total_duration_sec: float = 0.0
var current_seconds: float = 0.0:
	set(value):
		current_seconds = value
		queue_redraw()

var PIXELS_PER_SECOND: float = 150.0
var PIXELS_PER_SECOND_BACKING_VALUE: float = 150.0

const TOP_MARGIN: float = 30.0
const TRACK_HEIGHT: float = 30.0
const NOTE_PADDING: float = 5.0
const BORDER_WIDTH: float = 2.0
const NOTE_HEIGHT: float = TRACK_HEIGHT - (2 * NOTE_PADDING)

const EVENT_LANE_HEIGHT_BASE: float = 15.0
const EVENT_MARKER_SIZE: float = 4.0

var INPUT_BUFFER_SEC: float = 0.1
var NOTE_TAP_HOLD_THRESHOLD_SECONDS: float = 0.5

const COLOR_ON_BEAT: Color = Color.ORANGE
const COLOR_ON_BEAT_LET_GO: Color = Color.DARK_GOLDENROD
const COLOR_PAST: Color = Color(0.1, 0.4, 0.6, 0.8)
const COLOR_UPCOMING: Color = Color(0.2, 0.7, 0.3, 0.9)
const COLOR_TRACK_BG: Color = Color.GRAY * 0.3
const COLOR_PLAYHEAD: Color = Color.RED
const COLOR_BUFFER: Color = Color(0.1, 0.1, 0.1, 0.6)
const COLOR_NOTE_BORDER: Color = Color.BLACK

enum DRAW_MODE { NICE, HARD }

# Ggf. können damit noch bestimmte Input-Typen definiert und anders dargestellt werden...
# Aber... probably not
enum NODE_TYPE { TAP_A, TAP_B, TAB_AB, HOLD_A, HOLD_B, HOLD_AB }

var draw_mode: DRAW_MODE = DRAW_MODE.HARD
var pixel_tweener: Tween

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(InputHandler.DEBUG_TOGGLE_NOTE_UI):
		visible = !visible
		return

	var new_pixels: float = PIXELS_PER_SECOND_BACKING_VALUE
	var is_speed_change: bool = true

	if event.is_action_pressed(InputHandler.DEBUG_INCREASE_NOTE_UI_SPEED):
		new_pixels = min(PIXELS_PER_SECOND_BACKING_VALUE + 25, 1500)
	elif event.is_action_pressed(InputHandler.DEBUG_DECREASE_NOTE_UI_SPEED):
		new_pixels = max(PIXELS_PER_SECOND_BACKING_VALUE - 25, 25)
	elif event.is_action_pressed(InputHandler.DEBUG_RESET_NOTE_UI_SPEED):
		new_pixels = 150
	else:
		is_speed_change = false

	if is_speed_change:
		if new_pixels == PIXELS_PER_SECOND_BACKING_VALUE:
			return

		PIXELS_PER_SECOND_BACKING_VALUE = new_pixels

		if pixel_tweener:
			pixel_tweener.kill()

		pixel_tweener = create_tween()
		(
			pixel_tweener
			. tween_property(self, "PIXELS_PER_SECOND", new_pixels, 0.25)
			. set_ease(Tween.EASE_IN_OUT)
			. set_trans(Tween.TRANS_SINE)
		)


func _get_track_total_height(track_data: RhythmTrack) -> float:
	var num_event_lanes: int = track_data.events.keys().size()
	var total_event_height: float = float(num_event_lanes) * EVENT_LANE_HEIGHT_BASE
	return TRACK_HEIGHT + total_event_height


func set_rhythm_data(
	d: RhythmData, input_buffer_sec: float = 0.1, note_tap_hold_threshold_seconds: float = 0.5
) -> void:
	data = d
	total_duration_sec = 0.0
	INPUT_BUFFER_SEC = input_buffer_sec
	NOTE_TAP_HOLD_THRESHOLD_SECONDS = note_tap_hold_threshold_seconds

	if not data:
		custom_minimum_size = Vector2.ZERO
		queue_redraw()
		return

	var accumulated_height: float = 0.0

	for track: RhythmTrack in data.tracks:
		# Gesamtdauer berechnen (bzw dann wann die letzte Note spielt, kann also kürzer sein als das eigentliche Lied).
		for note: RhythmNote in track.notes:
			total_duration_sec = max(total_duration_sec, note.start + note.duration)
			
			var linked_events: Array[RhythmTriggerEvent] = []
			for event_array: Array in track.events.values():
				for event: RhythmTriggerEvent in event_array:
					if event.note == note:
						linked_events.append(event)
			
			note_events[note] = linked_events
			
		# Das gleiche nochmal mit Events. Events mit positivem offset können entsprechend nach der letzten
		# Note triggern.
		for event_array: Array in track.events.values():
			for event: RhythmTriggerEvent in event_array:
				total_duration_sec = max(total_duration_sec, event.time)

		accumulated_height += _get_track_total_height(track)

	var timeline_width: float = total_duration_sec * PIXELS_PER_SECOND
	var total_vis_height: float = accumulated_height + TOP_MARGIN

	custom_minimum_size = Vector2(timeline_width + 50.0, total_vis_height + 50.0)

	queue_redraw()

# Array[RhythmTriggerEvent]
var note_events: Dictionary[RhythmNote, Array] = {}

func _draw() -> void:
	if not data or data.tracks.is_empty() or is_zero_approx(total_duration_sec):
		return

	# Positionierung + optimierung (rudimentäres culling wenn beides, also Note und Event nicht sichtbar sind)
	var viewport_size: Vector2 = get_viewport_rect().size
	var fixed_center_x: float = viewport_size.x / 2.0
	var content_playhead_x: float = current_seconds * PIXELS_PER_SECOND
	var offset_x: float = fixed_center_x - content_playhead_x

	var culling_pixels: float = viewport_size.x / 2.0 + (INPUT_BUFFER_SEC * PIXELS_PER_SECOND * 2.0)
	var start_x_visible: float = content_playhead_x - culling_pixels
	var end_x_visible: float = content_playhead_x + culling_pixels

	var start_time_visible: float = start_x_visible / PIXELS_PER_SECOND
	var end_time_visible: float = end_x_visible / PIXELS_PER_SECOND

	var font: Font = get_theme_default_font()
	var font_size: int = get_theme_default_font_size()
	var current_y_offset: float = TOP_MARGIN

	var timeline_width: float = total_duration_sec * PIXELS_PER_SECOND

	for idx: int in data.tracks.size():
		var track_data: RhythmTrack = data.tracks[idx]

		var track_full_height: float = _get_track_total_height(track_data)
		var note_lane_y: float = current_y_offset
		var events_base_y: float = current_y_offset + TRACK_HEIGHT

		# Hintergrund (grau)
		var bg_rect_2: Rect2 = Rect2(offset_x, current_y_offset, timeline_width, track_full_height)
		draw_rect(bg_rect_2, COLOR_TRACK_BG)

		# janky ass gebastel um events und tracks zu verarbeiten...
		var event_keys: Array[StringName] = track_data.events.keys()
		var event_y_map: Dictionary = {}

		for event_idx: int in event_keys.size():
			var event_identifier: StringName = event_keys[event_idx]
			var event_array: Array = track_data.events[event_identifier]
			var event_debug_color_base: Color = event_array.front().debug_color

			var event_lane_y_center: float = (
				events_base_y
				+ (float(event_idx) * EVENT_LANE_HEIGHT_BASE)
				+ (EVENT_LANE_HEIGHT_BASE / 2.0)
			)
			event_y_map[event_identifier] = event_lane_y_center

			var event_string: String = ""
			if event_array.front().use_beats:
				event_string = "↳ %s (triggers: %d, offset: %.2f beats)" % [event_identifier, event_array.size(), event_array.front().offset_beats]
			else:
				event_string = "↳ %s (triggers: %d, offset: %.2f seconds)" % [event_identifier, event_array.size(), event_array.front().offset]

			draw_string(
				font,
				Vector2(25, event_lane_y_center + (font_size * 0.4)),
				(
					event_string
					#"↳ %s (triggers: %d, offset: %.2f)"
					#% [event_identifier, event_array.size(), event_array.front().offset]
				),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size,
				event_debug_color_base
			)
			
		# Noten und events zeichnen
		for note: RhythmNote in track_data.notes:
			var note_start_sec: float = note.start
			var note_end_sec: float = note.start + note.duration

			# culling logik
			#var linked_events: Array = []
			var note_is_visible: bool = false

			if not (note_end_sec < start_time_visible or note_start_sec > end_time_visible):
				note_is_visible = true
				
			#for event_array: Array in track_data.events.values():
			#	for event: RhythmTriggerEvent in event_array:
			#		if event.note == note:
			#			linked_events.append(event)

			#			# falls note nicht sichtbar, prüfe ob dazugehöriges event sichtbar ist
			#			if not note_is_visible:
			#				var event_time: float = event.time
			#				var min_time: float = min(note_start_sec, event_time)
			#				var max_time: float = max(note_start_sec, event_time)

			#				if not (max_time < start_time_visible or min_time > end_time_visible):
			#					note_is_visible = true

			if not note_is_visible:
				continue

			# noten zeichnen (+ input buffers + tap/hold marker)
			var start_x: float = note_start_sec * PIXELS_PER_SECOND
			var duration_w: float = note.duration * PIXELS_PER_SECOND
			var draw_start_x: float = start_x + offset_x
			var buffer_w: float = INPUT_BUFFER_SEC * PIXELS_PER_SECOND
			var is_hold: bool = note.duration >= NOTE_TAP_HOLD_THRESHOLD_SECONDS

			var draw_color: Color
			match draw_mode:
				DRAW_MODE.NICE:
					if note_end_sec < current_seconds:
						draw_color = COLOR_PAST
					elif note_start_sec < current_seconds:
						var progress: float = (current_seconds - note_start_sec) / note.duration
						draw_color = lerp(COLOR_UPCOMING, COLOR_PAST, progress)
					else:
						draw_color = COLOR_UPCOMING
				DRAW_MODE.HARD:
					if (
						is_hold
						and note_end_sec - INPUT_BUFFER_SEC < current_seconds
						and note_end_sec + INPUT_BUFFER_SEC > current_seconds
					):
						draw_color = COLOR_ON_BEAT_LET_GO
					elif note_start_sec + INPUT_BUFFER_SEC < current_seconds:
						draw_color = COLOR_PAST
					elif note_start_sec - INPUT_BUFFER_SEC < current_seconds:
						draw_color = COLOR_ON_BEAT
					else:
						draw_color = COLOR_UPCOMING

			# note
			var note_rect: Rect2 = Rect2(
				draw_start_x, note_lane_y + NOTE_PADDING, duration_w, NOTE_HEIGHT
			)
			draw_rect(note_rect, draw_color)
			draw_rect(note_rect, COLOR_NOTE_BORDER, false, 1.0)

			var half_note_h: float = NOTE_HEIGHT * 0.5
			var buffer_rect_h: float = half_note_h
			var buffer_rect_y: float = note_lane_y + NOTE_PADDING + NOTE_HEIGHT * 0.25

			if is_hold:
				var marker_color: Color = draw_color * 1.4
				var triangle_center_x: float = draw_start_x
				if duration_w < NOTE_HEIGHT * 2:
					triangle_center_x = draw_start_x + duration_w / 2.0

				var p1: Vector2 = Vector2(
					triangle_center_x + BORDER_WIDTH * 0.5, 
					note_lane_y + NOTE_PADDING + BORDER_WIDTH
				)
				var p2: Vector2 = Vector2(
					draw_start_x + duration_w * 0.2, note_lane_y + NOTE_PADDING + half_note_h
				)
				var p3: Vector2 = Vector2(
					triangle_center_x + BORDER_WIDTH * 0.5,
					note_lane_y + NOTE_HEIGHT + NOTE_PADDING - BORDER_WIDTH
				)
				draw_polygon([p1, p2, p3], [marker_color])

				# late buffer (nur hold notes haben einen late buffer, da tap notes natürlich nie
				# "losgelassen" werden müssen)
				var late_buffer_start_x: float = draw_start_x + duration_w - buffer_w
				var late_buffer_rect: Rect2 = Rect2(
					late_buffer_start_x, buffer_rect_y, buffer_w * 2.0, buffer_rect_h
				)
				draw_rect(late_buffer_rect, COLOR_BUFFER)
				
			# early buffer
			var early_buffer_start_x: float = draw_start_x - buffer_w
			var early_buffer_rect: Rect2 = Rect2(
				early_buffer_start_x, buffer_rect_y, buffer_w * 2.0, buffer_rect_h
			)
			draw_rect(early_buffer_rect, COLOR_BUFFER)

			var note_link_y: float = note_lane_y + NOTE_PADDING + half_note_h

			# events
			for event: RhythmTriggerEvent in note_events[note]:
				var event_link_y: float = event_y_map.get(event.identifier, -1.0)
				if event_link_y == -1.0:
					continue

				var event_x_on_screen: float = (event.time * PIXELS_PER_SECOND) + offset_x

				if not (event_x_on_screen < start_time_visible or event_x_on_screen > end_time_visible):
					continue

				# verbindungslinie
				draw_line(
					Vector2(draw_start_x, note_link_y),
					Vector2(event_x_on_screen, event_link_y),
					event.debug_color.lightened(0.5) * Color(1.0, 1.0, 1.0, 0.4),
					1.0,
					true
				)

				# event marker (punkt)
				draw_circle(
					Vector2(event_x_on_screen, event_link_y), EVENT_MARKER_SIZE, event.debug_color
				)

		# trackname label
		draw_string(
			font,
			Vector2(5, note_lane_y + TRACK_HEIGHT / 2.0 + (font_size / 2.0)),
			"%d: %s (events: %d)" % [idx, track_data.name, event_keys.size()],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			Color.WHITE
		)

		current_y_offset += track_full_height

	# data.custom_events
	var bg_rect: Rect2 = Rect2(offset_x, current_y_offset, timeline_width, TRACK_HEIGHT)
	draw_rect(bg_rect, COLOR_TRACK_BG)
	
	var custom_event_lane_y_center: float = (
		current_y_offset
		+ (EVENT_LANE_HEIGHT_BASE * 1.25)
	)
	
	for event: RhythmTriggerEvent in data.custom_events:
		var event_time: float = event.time
		
		if event_time < start_time_visible or event_time > end_time_visible:
			continue
			
		var event_x_on_screen: float = (event.time * PIXELS_PER_SECOND) + offset_x
			
		draw_circle(
			Vector2(event_x_on_screen, custom_event_lane_y_center), EVENT_MARKER_SIZE, event.debug_color
		)
		
		draw_string(
			font,
			Vector2(event_x_on_screen - 125.0, custom_event_lane_y_center + font_size * 2.0),
			event.identifier,
			HORIZONTAL_ALIGNMENT_CENTER,
			250,
			font_size,
			event.debug_color
		)
	
	draw_string(
		font,
		Vector2(5, current_y_offset + TRACK_HEIGHT / 2.0 + (font_size / 2.0)),
		"Custom Events (events: %d)" % data.custom_events.size(),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color.WHITE if not data.custom_events.is_empty() else Color.GRAY
	)

	var playhead_x: float = fixed_center_x
	var total_vis_height_draw: float = current_y_offset

	# Playhead (rote linie, "jetzt" im Lied)
	draw_line(
		Vector2(playhead_x, TOP_MARGIN),
		Vector2(playhead_x, total_vis_height_draw + TRACK_HEIGHT),
		COLOR_PLAYHEAD,
		2.0
	)

	# aktuelle Zeit im Lied
	draw_string(
		font,
		Vector2(playhead_x - 50, TOP_MARGIN - NOTE_PADDING * 2),
		"%0.2fs" % current_seconds,
		HORIZONTAL_ALIGNMENT_CENTER,
		100,
		font_size,
		Color.WHITE
	)

	draw_string(
		font,
		Vector2(viewport_size.x - 200, TOP_MARGIN - NOTE_PADDING * 2),
		"%d pixels/s" % PIXELS_PER_SECOND,
		HORIZONTAL_ALIGNMENT_RIGHT,
		200
	)
