class_name Coin
extends Area2D
## Монетка: при касании игроком испускает сигнал collected, «лопается»
## (растёт и растворяется) и выбрасывает облако искр.

## Испускается в момент сбора (до анимации и queue_free()).
signal collected(coin: Coin)

const SPARK_SCENE := preload("res://spark_particles.tscn")

## Длительность эффекта исчезновения, секунды.
const POP_TIME := 0.2
## Во сколько раз вырастает спрайт за время эффекта.
const POP_SCALE := 2.0

var _collected := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	# Мониторинг меняется только отложенно — мы внутри физического колбэка.
	set_deferred("monitoring", false)
	collected.emit(self)
	_spawn_sparks()
	_play_collect_effect()


## Взрыв искр в точке монетки. Искры добавляются к родителю монетки,
## потому что сама монетка удалится через POP_TIME.
func _spawn_sparks() -> void:
	var sparks := SPARK_SCENE.instantiate() as CPUParticles2D
	sparks.name = "Sparks"
	get_parent().add_child(sparks)
	sparks.global_position = global_position
	sparks.emitting = true


## Параллельный твин: спрайт растёт и растворяется, затем узел удаляется.
func _play_collect_effect() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_sprite, "scale", _sprite.scale * POP_SCALE, POP_TIME)
	tween.tween_property(_sprite, "modulate:a", 0.0, POP_TIME)
	await tween.finished
	queue_free()
