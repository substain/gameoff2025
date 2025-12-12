class_name MainMenuWithBackground
extends Node

@onready var menu: Menu = $Menu
@onready var bg_sky: Sprite2D = $BGSky
@onready var game_map: GameMap = $GameMap
@onready var bg_clouds: Sprite2D = $Parallax2D/BGClouds

@export var simulate_mobile: bool = false

func _enter_tree() -> void:
	check_is_mobile()


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
	
func check_is_mobile() -> void:
	var is_mobile: bool = OS.get_name() == "Android" || OS.get_name() == "iOS" || OS.has_feature("web_android") || OS.has_feature("web_ios") 
	if simulate_mobile && OS.has_feature("editor"):
		if ProjectSettings.get("input_devices/pointing/emulate_touch_from_mouse") as bool == false:
			push_error("trying to emulate mobile, but correct project setting is not set ('input_devices/pointing/emulate_touch_from_mouse')")
		is_mobile = true

	GameState.is_mobile = is_mobile
