class_name SettingsMenu
extends Control

signal back_button_pressed

func _ready() -> void:
	pass


func _on_back_button_pressed() -> void:
	back_button_pressed.emit()
