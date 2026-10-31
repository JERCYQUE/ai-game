extends CharacterBody2D
## Игрок: движение по экрану стрелками или WASD, с ограничением по границам.

## Испускается при первом реальном вводе движения — по нему запускается таймер.
signal movement_started

## Скорость движения в пикселях в секунду.
@export var speed: float = 300.0

## Половина размера спрайта — на столько игрок «упирается» в край экрана.
@export var half_extents: Vector2 = Vector2(64, 64)

var _movement_reported := false


func _physics_process(_delta: float) -> void:
	# get_vector сам нормализует диагональ, чтобы по диагонали не было быстрее.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if not _movement_reported and direction != Vector2.ZERO:
		_movement_reported = true
		movement_started.emit()

	velocity = direction * speed
	move_and_slide()
	_clamp_to_viewport()


## Не даёт игроку выехать за границы видимой области.
func _clamp_to_viewport() -> void:
	var bounds := get_viewport_rect()
	global_position = global_position.clamp(bounds.position + half_extents, bounds.end - half_extents)
