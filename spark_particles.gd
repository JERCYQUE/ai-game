extends CPUParticles2D
## Разовый «взрыв» искр. Сцена сама удаляется, когда частицы отработали.

func _ready() -> void:
	# Чистим себя таймером, а не сигналом finished: у CPUParticles2D finished
	# приходит сразу после входа в дерево (emitting ещё false), и узел
	# удалялся бы в том же кадре, не успев ничего нарисовать.
	var cleanup := get_tree().create_timer(lifetime + 0.5)
	cleanup.timeout.connect(queue_free)
