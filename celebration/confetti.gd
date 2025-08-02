extends Node2D
class_name Confetti

func startEffect()->void:
	$CPUParticles2D.emitting = true
	$AudioStreamPlayer2D.play()
