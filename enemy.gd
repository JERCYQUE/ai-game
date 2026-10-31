class_name Enemy
extends Area2D
## Враг: плавно патрулирует влево-вправо по синусоиде и ловит игрока.

## Испускается, когда враг коснулся игрока.
signal caught_player

## Амплитуда патруля в пикселях (в каждую сторону от стартовой точки).
@export var amplitude: float = 110.0
## Угловая скорость патруля, радиан в секунду.
@export var speed: float = 1.3

var _origin_x: float = 0.0
var _start_time: float = 0.0
var _caught: bool = false


func _ready() -> void:
	_origin_x = position.x
	# Якорь фазы: Time.get_ticks_msec() считается от старта движка,
	# без якоря враг на первом кадре прыгал бы в случайную точку.
	_start_time = Time.get_ticks_msec() / 1000.0
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 - _start_time
	position.x = _origin_x + sin(t * speed) * amplitude


func _on_body_entered(body: Node2D) -> void:
	if _caught or not body.is_in_group("player"):
		return
	_caught = true
	set_deferred("monitoring", false)
	caught_player.emit()
