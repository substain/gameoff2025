class_name RhythmData
extends RefCounted

var tracks: Array[RhythmTrack] = []
var tempo_map: Array[RhythmTempoMapEntry] = []

var custom_events: Array[RhythmTriggerEvent] = []

func get_bpm_at_time(time_sec: float) -> float:
	if tempo_map.is_empty():
		return 120.0
		
	var current_bpm: float = 120.0
	for tempo_event: RhythmTempoMapEntry in tempo_map:
		if tempo_event.time <= time_sec:
			current_bpm = tempo_event.bpm
		else:
			break
			 
	return current_bpm

func get_bps_at_time(time_sec: float) -> float:
	return get_bpm_at_time(time_sec) / 60.0
