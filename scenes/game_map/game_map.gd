class_name GameMap
extends Node2D

@export_file_path var zen_garden_level_path: String = ""
@export_file_path var surfing_level_path: String = ""
@export_file_path var angler_fish_level_path: String = ""
@export_file_path var glowsticks_level_path: String = ""

@export var level_buttons: Array[BaseButton] = []

enum LevelType {
	ZEN_GARDEN,
	SURFING,
	ANGLER_FISH,
	GLOWSTICKS
}

func _process(_delta: float) -> void:
	pass


func switch_level(level_type: LevelType) -> void:
	var level_to_load_file_path: String = ""

	match level_type:
		LevelType.ZEN_GARDEN:
			level_to_load_file_path = zen_garden_level_path
		LevelType.SURFING:
			level_to_load_file_path = surfing_level_path
		LevelType.ANGLER_FISH:
			level_to_load_file_path = angler_fish_level_path
		LevelType.GLOWSTICKS:
			level_to_load_file_path = glowsticks_level_path
		
		_:
			push_warning("level type '", LevelType.keys()[level_type], "' has no implementation")
			return
	
	if level_to_load_file_path == "":
		push_warning("empty file path found for '", LevelType.keys()[level_type], "'")
		return

		
	get_tree().change_scene_to_file(level_to_load_file_path)

func _on_zen_garden_level_button_pressed() -> void:
	switch_level(LevelType.ZEN_GARDEN)

func _on_surf_level_button_pressed() -> void:
	switch_level(LevelType.SURFING)

func _on_angler_fish_level_button_pressed() -> void:
	switch_level(LevelType.ANGLER_FISH)

func _on_glowsticks_button_pressed() -> void:
	switch_level(LevelType.GLOWSTICKS)


func _on_button_pressed() -> void:
	var select_a_level: int=randi_range(0, LevelType.values().size())
	print(select_a_level)
	switch_level(select_a_level)
