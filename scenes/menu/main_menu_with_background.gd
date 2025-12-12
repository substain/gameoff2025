class_name MainMenuWithBackground
extends Node

@onready var menu: Menu = $Menu
@onready var bg_sky: Sprite2D = $BGSky
@onready var game_map: GameMap = $GameMap
@onready var bg_clouds: Sprite2D = $Parallax2D/BGClouds

func _on_menu_game_started() -> void:
	menu.visible = false
	
	var tween: Tween = create_tween().set_parallel(true)
	#tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(bg_clouds, "modulate:a", 0.0, 2.5)
	tween.tween_property(bg_clouds, "global_position:y", bg_clouds.global_position.y + 100, 3.5)
	
	await get_tree().create_timer(0.5).timeout
	
	var tween2: Tween = create_tween().set_parallel(true)
	tween2.tween_property(bg_sky, "modulate:a", 0.0, 1.5)
	tween2.tween_property(game_map, "scale", Vector2(1.1, 1.1), 1.5)
	
	await get_tree().create_timer(1.5).timeout
	game_map.start_randomize()
	
