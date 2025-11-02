extends Node2D



var sound_snippet_children: Array[SoundSnippet] = []

func _ready() -> void:
	for node: Node in get_children():
		if !(node is SoundSnippet):
			return
			
		sound_snippet_children.append(node as SoundSnippet)
		
	Globals.on_start_game.connect(_on_start)
	Globals.on_stop_game.connect(_on_stop)
		

func _on_start() -> void:
	for soundsnippet: SoundSnippet in sound_snippet_children:
		soundsnippet.set_active()
		
func _on_stop() -> void:
	for soundsnippet: SoundSnippet in sound_snippet_children:
		soundsnippet.set_inactive()
				
		
