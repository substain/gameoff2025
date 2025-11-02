class_name GameMap
extends Node2D

@export_file_path var zen_garden_file_path: String = ""
@export_file_path var zen_garden_singing_file_path: String = ""
@export_file_path var surfing_file_path: String = ""
@export_file_path var angler_fish_path: String = ""


enum LevelType {
	ZEN_GARDEN,
	ZEN_GARDEN_SINGING,
	SURFING,
	ANGLER_FISH	
}

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass


func switch_level(level_type: LevelType) -> void:
	var level_to_load_file_path: String = ""

	match level_type:
		LevelType.ZEN_GARDEN:
			level_to_load_file_path = zen_garden_file_path
		LevelType.ZEN_GARDEN_SINGING:
			level_to_load_file_path = zen_garden_singing_file_path
		LevelType.SURFING:
			level_to_load_file_path = surfing_file_path
		LevelType.ANGLER_FISH:
			level_to_load_file_path = angler_fish_path
	
	get_tree().change_scene_to_file(level_to_load_file_path)


func _on_zen_garden_level_button_pressed() -> void:
	switch_level(LevelType.ZEN_GARDEN)

func _on_zen_garden_singing_level_button_pressed() -> void:
	switch_level(LevelType.ZEN_GARDEN_SINGING)

func _on_surf_level_button_pressed() -> void:
	switch_level(LevelType.SURFING)

func _on_angler_fish_level_button_pressed() -> void:
	switch_level(LevelType.ANGLER_FISH)
