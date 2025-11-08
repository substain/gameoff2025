class_name CYSEnemyBoxArea
extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is CYSPlayer:
		(body as CYSPlayer).die()
