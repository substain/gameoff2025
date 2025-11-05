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
const TRACK_HEIGHT: float = 30.0
const NOTE_PADDING: float = 5.0
const BORDER_WIDTH: float = 2.0
const NOTE_HEIGHT: float = TRACK_HEIGHT - (2 * NOTE_PADDING)

var INPUT_BUFFER_SEC: float = 0.1  # 50ms early/late -> 100ms total
var NOTE_TAP_HOLD_THRESHOLD_SECONDS: float = 0.5

const COLOR_ON_BEAT: Color = Color.ORANGE
const COLOR_ON_BEAT_LET_GO: Color = Color.DARK_GOLDENROD
const COLOR_PAST: Color = Color(0.1, 0.4, 0.6, 0.8)
const COLOR_UPCOMING: Color = Color(0.2, 0.7, 0.3, 0.9)
const COLOR_TRACK_BG: Color = Color.GRAY * 0.3
const COLOR_PLAYHEAD: Color = Color.RED
const COLOR_BUFFER: Color = Color(0.1, 0.1, 0.1, 0.6) 
const COLOR_NOTE_BORDER: Color = Color.BLACK


enum DRAW_MODE {
	NICE,
	HARD
}

enum NODE_TYPE {
	TAP_A,
	TAP_B,
	TAB_AB,
	HOLD_A,
	HOLD_B,
	HOLD_AB
}

var draw_mode: DRAW_MODE = DRAW_MODE.HARD

var pixel_tweener: Tween

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_note_ui"):
		visible = !visible
	elif event.is_action_pressed("debug_increase_note_ui_speed"):
		var new_pixels: float = min(PIXELS_PER_SECOND_BACKING_VALUE + 25, 1500)
		PIXELS_PER_SECOND_BACKING_VALUE = new_pixels
		if pixel_tweener != null:
			pixel_tweener.kill()
			
		pixel_tweener = create_tween()
		
		pixel_tweener.tween_property(self, "PIXELS_PER_SECOND", new_pixels, 0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	elif event.is_action_pressed("debug_decrease_note_ui_speed"):
		var new_pixels: float = max(PIXELS_PER_SECOND_BACKING_VALUE - 25, 25)
		PIXELS_PER_SECOND_BACKING_VALUE = new_pixels
		if pixel_tweener != null:
			pixel_tweener.kill()
			
		pixel_tweener = create_tween()
		
		pixel_tweener.tween_property(self, "PIXELS_PER_SECOND", new_pixels, 0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	elif event.is_action_pressed("debug_reset_note_ui_speed"):
		var new_pixels: float = 150
		PIXELS_PER_SECOND_BACKING_VALUE = new_pixels
		if pixel_tweener != null:
			pixel_tweener.kill()
			
		pixel_tweener = create_tween()
		
		pixel_tweener.tween_property(self, "PIXELS_PER_SECOND", new_pixels, 0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func set_rhythm_data(d: RhythmData, input_buffer_sec: float = 0.1, note_tap_hold_threshold_seconds: float = 0.5) -> void:
	data = d
	total_duration_sec = 0.0
	INPUT_BUFFER_SEC = input_buffer_sec
	NOTE_TAP_HOLD_THRESHOLD_SECONDS = note_tap_hold_threshold_seconds
	
	if not data:
		custom_minimum_size = Vector2.ZERO
		queue_redraw()
		return
	
	for track: RhythmTrack in data.tracks:
		for note: RhythmNote in track.notes:
			total_duration_sec = max(total_duration_sec, note.start + note.duration)
	
	var timeline_width: float = total_duration_sec * PIXELS_PER_SECOND
	var total_vis_height: float = data.tracks.size() * TRACK_HEIGHT
	custom_minimum_size = Vector2(timeline_width + 50.0, total_vis_height + 50.0)
	
	queue_redraw()


func _draw() -> void:
	if not data or data.tracks.is_empty() or is_zero_approx(total_duration_sec):
		return
		
	# offset berechnen
	var viewport_size: Vector2 = get_viewport_rect().size
	var fixed_center_x: float = viewport_size.x / 2.0
	var content_playhead_x: float = current_seconds * PIXELS_PER_SECOND
	var offset_x: float = fixed_center_x - content_playhead_x

	# Berechnen ob und welche Noten überhaupt sichtbar sind
	# Quasi rudimentäres culling.
	var start_time_visible: float = current_seconds - (fixed_center_x / PIXELS_PER_SECOND)
	# "Zeit" am rechteten Bildschirmrand (rechtester Pixel)
	var end_time_visible: float = (
		current_seconds + ((viewport_size.x - fixed_center_x) / PIXELS_PER_SECOND)
	)

	# Kleiner buffer um pop-in zu verhindern
	var culling_margin_sec: float = INPUT_BUFFER_SEC * 2.0
	start_time_visible -= culling_margin_sec
	end_time_visible += culling_margin_sec

	# Über tracks gehen und infos zeichnen
	for idx: int in data.tracks.size():
		var track_data: RhythmTrack = data.tracks[idx]
		var track_y_pos: float = float(idx+1) * TRACK_HEIGHT

		# Grauer Hintergrund
		var timeline_width: float = total_duration_sec * PIXELS_PER_SECOND
		var bg_rect: Rect2 = Rect2(offset_x, track_y_pos, timeline_width, TRACK_HEIGHT)
		draw_rect(bg_rect, COLOR_TRACK_BG)

		var font: Font = get_theme_default_font()
		var font_size: int = get_theme_default_font_size()

		# Über einzelne "noten" im Track iterieren
		for note: RhythmNote in track_data.notes:
			var note_start_sec: float = note.start
			var note_end_sec: float = note.start + note.duration

			# Schauen ob Note überhaupt sichtbar ("culling")
			if note_end_sec < start_time_visible || note_start_sec > end_time_visible:
				continue

			var start_x: float = note_start_sec * PIXELS_PER_SECOND
			var duration_w: float = note.duration * PIXELS_PER_SECOND
			var draw_start_x: float = start_x + offset_x
			var buffer_w: float = INPUT_BUFFER_SEC * PIXELS_PER_SECOND

			var is_hold: bool = note.duration >= NOTE_TAP_HOLD_THRESHOLD_SECONDS

			# Je nach Modus und Position andere Farbe wählen
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
					# TODO: make not end highlight during buffer
					if is_hold and note_end_sec - INPUT_BUFFER_SEC < current_seconds and note_end_sec + INPUT_BUFFER_SEC > current_seconds:
						draw_color = COLOR_ON_BEAT_LET_GO
					elif note_start_sec + INPUT_BUFFER_SEC < current_seconds:
						draw_color = COLOR_PAST
					elif note_start_sec - INPUT_BUFFER_SEC < current_seconds:
						draw_color = COLOR_ON_BEAT
					else:
						draw_color = COLOR_UPCOMING
					#if note_end_sec < current_seconds:
					#	draw_color = COLOR_PAST
					#elif note_start_sec < current_seconds:
					#	var progress = (current_seconds - note_start_sec) / note.duration
					#	draw_color = lerp(COLOR_UPCOMING, COLOR_PAST, progress)
					#else:
					#	draw_color = COLOR_UPCOMING

			# Eigentliche Note Zeichnen
			var note_rect: Rect2 = Rect2(draw_start_x, track_y_pos + NOTE_PADDING, duration_w, NOTE_HEIGHT)
			draw_rect(note_rect, draw_color)
			draw_rect(note_rect, COLOR_NOTE_BORDER, false, 1.0)
			
			# TODO: Tap vs Hold
			# "Marker" Zeichnen um zu zeigen ob eine Note Tap oder Hold ist
			# Ich wollte nicht noch mehr Farben einbauen, komme jetzt schon fast durcheinander
			# Für Hold gibts quasi eine Art "dreieck"
			
			if is_hold:
				var marker_color: Color = draw_color * 1.4 # COLOR_NOTE_BORDER
				# marker_color.a = 1.0
				#marker_color = COLOR_NOTE_BORDER
				
				var triangle_center_x: float = draw_start_x #+ min(duration_w / 2.0, NOTE_HEIGHT) 
				if duration_w < NOTE_HEIGHT * 2: # Keep triangle visible for short hold notes
					triangle_center_x = draw_start_x + duration_w / 2.0
					
				var p1: Vector2 = Vector2(triangle_center_x + BORDER_WIDTH * 0.5, track_y_pos + NOTE_PADDING + BORDER_WIDTH)
				var p2: Vector2 = Vector2(triangle_center_x + duration_w * 0.2, track_y_pos + NOTE_PADDING + NOTE_HEIGHT * 0.5)
				var p3: Vector2 = Vector2(triangle_center_x + BORDER_WIDTH * 0.5, track_y_pos + NOTE_HEIGHT + NOTE_PADDING - BORDER_WIDTH)
				
				draw_polygon([p1, p2, p3], [marker_color])
			
			# Buffer am Anfang einer Note (für Tap + Hold)
			var early_buffer_start_x: float = draw_start_x - buffer_w
			var early_buffer_rect: Rect2 = Rect2(
				early_buffer_start_x,
				track_y_pos + NOTE_PADDING + NOTE_HEIGHT * 0.25,
				buffer_w * 2.0,
				NOTE_HEIGHT * 0.5
			)
			draw_rect(early_buffer_rect, COLOR_BUFFER)
			
			if is_hold:
				# Buffer am Ende einer Note (nur Hold)
				var late_buffer_start_x: float = draw_start_x + duration_w - buffer_w
				var late_buffer_rect: Rect2 = Rect2(
					late_buffer_start_x,
					track_y_pos + NOTE_PADDING + NOTE_HEIGHT * 0.25,
					buffer_w * 2.0,
					NOTE_HEIGHT * 0.5
				)
				draw_rect(late_buffer_rect, COLOR_BUFFER)
			
		draw_string(
			font,
			Vector2(5, track_y_pos + TRACK_HEIGHT / 2.0 + (font_size / 2.0)),
			"%d: %s" % [idx, track_data.name],
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			font_size,
			Color.WHITE
		)

		# Rote Linie Zeichnen ("Playhead")
		var playhead_x: float = fixed_center_x
		var total_vis_height_draw: float = data.tracks.size() * TRACK_HEIGHT

		draw_line( 
			Vector2(playhead_x, TRACK_HEIGHT), Vector2(playhead_x, total_vis_height_draw + TRACK_HEIGHT), COLOR_PLAYHEAD, 2.0
		)

		# Aktuelle Playtime der Audiodatei anzeigen
		draw_string(
			font,
			Vector2(playhead_x - 50, TRACK_HEIGHT - NOTE_PADDING * 2),
			"%0.2fs" % current_seconds,
			HORIZONTAL_ALIGNMENT_CENTER,
			100,
			font_size,
			Color.WHITE
		)	
		
		# Pixels per Second anzeigen
		draw_string(font, Vector2(0, TRACK_HEIGHT - NOTE_PADDING * 2), "%d pixels/s" % PIXELS_PER_SECOND, HORIZONTAL_ALIGNMENT_LEFT)
