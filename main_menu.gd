extends Control
## Главное меню: кнопка «Начать» переключает на игровую сцену.

const GAME_SCENE := "res://main.tscn"

@onready var _start_button: Button = $Center/Menu/StartButton


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_start_button.grab_focus()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
