class_name OilSpill
extends Area2D

func _on_area_entered(_area: Area2D) -> void:
	$AudioStreamPlayer.play()
