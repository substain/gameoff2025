class_name CYSAddedSounds
extends Node2D

var sound_snippet_children: Array[CYSSoundSnippet] = []

func _ready() -> void:
	for node: Node in get_children():
		if !(node is CYSSoundSnippet):
			return
			
		sound_snippet_children.append(node as CYSSoundSnippet)
		
	CYSGlobals.on_start_game.connect(_on_start)
	CYSGlobals.on_stop_game.connect(_on_stop)
		

func _on_start() -> void:
	for soundsnippet: CYSSoundSnippet in sound_snippet_children:
		soundsnippet.set_active()
		
func _on_stop() -> void:
	for soundsnippet: CYSSoundSnippet in sound_snippet_children:
		soundsnippet.set_inactive()
				
		
