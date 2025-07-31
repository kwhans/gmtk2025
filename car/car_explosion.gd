extends CPUParticles2D
class_name CarExplosion

func _ready() -> void:
	emitting = true
	$CrashSound.play()

func _on_finished() -> void:
	$CleanupTimer.start()

func _on_cleanup_timer_timeout() -> void:
	queue_free()
