class_name OilSpill
extends Area2D



func _on_body_entered(body: Node2D) -> void:
	$AudioStreamPlayer.play()
	if body is Car:
		body.applyOil()
