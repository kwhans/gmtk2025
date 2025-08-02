extends Node2D
class_name Firework

func startEffect()->void:
	$CPUParticles2D.emitting = true
	$AudioStreamPlayer2D.play()
