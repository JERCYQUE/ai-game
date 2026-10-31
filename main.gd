extends Node2D
## Игровой цикл: счёт, таймер, победа/поражение, ловля врагом, рекорды и рестарт.

const WIN_MESSAGE := "Победа!"
const LOSE_MESSAGE := "Время вышло!"
const CAUGHT_MESSAGE := "Вас поймали!"

## Рекорды храним в user:// (переживает перезапуск игры).
const SAVE_PATH := "user://highscore.cfg"
const RECORDS_SECTION := "records"
const BEST_TIME_KEY := "best_time"

@onready var _score_label: Label = $UI/UIRoot/Hud/Info/ScoreLabel
@onready var _timer_label: Label = $UI/UIRoot/Hud/Info/TimerLabel
@onready var _best_label: Label = $UI/UIRoot/BestLabel
@onready var _message_panel: Panel = $UI/UIRoot/MessagePanel
@onready var _result_label: Label = $UI/UIRoot/MessagePanel/Content/ResultLabel
@onready var _restart_button: Button = $UI/UIRoot/MessagePanel/Content/RestartButton
@onready var _game_timer: Timer = $GameTimer
@onready var _player: CharacterBody2D = $Player

@onready var _sfx_coin: AudioStreamPlayer = $SfxCoin
@onready var _sfx_win: AudioStreamPlayer = $SfxWin
@onready var _sfx_lose: AudioStreamPlayer = $SfxLose
@onready var _sfx_caught: AudioStreamPlayer = $SfxCaught

var score: int = 0
var total_coins: int = 0
var game_over: bool = false

## Лучшее время прохождения в секундах; -1.0 — рекорда ещё нет.
var best_time: float = -1.0

## Запущен ли таймер (до первого движения он стоит и показывает полное время).
var _timer_started: bool = false


func _ready() -> void:
	var coins := get_tree().get_nodes_in_group("coins")
	total_coins = coins.size()
	for node in coins:
		var coin := node as Coin
		if coin:
			coin.collected.connect(_on_coin_collected)

	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy:
			enemy.caught_player.connect(_on_enemy_caught)

	_game_timer.timeout.connect(_on_game_timer_timeout)
	_restart_button.pressed.connect(_on_restart_pressed)

	# Таймер стартует не здесь, а по первому движению игрока.
	_player.movement_started.connect(_on_player_movement_started)

	_load_best_time()
	_message_panel.hide()
	_update_hud()


func _process(_delta: float) -> void:
	if game_over:
		return
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		_restart_game()


## Первое движение игрока запускает отсчёт.
func _on_player_movement_started() -> void:
	if _timer_started or game_over:
		return
	_timer_started = true
	_game_timer.start()


func _on_restart_pressed() -> void:
	_restart_game()


func _restart_game() -> void:
	get_tree().reload_current_scene()


func _on_coin_collected(_coin: Coin) -> void:
	if game_over:
		return
	_sfx_coin.play()
	score += 1
	_update_hud()
	if score >= total_coins:
		_register_win()
		_end_game(WIN_MESSAGE)


func _on_enemy_caught() -> void:
	_end_game(CAUGHT_MESSAGE)


func _on_game_timer_timeout() -> void:
	_end_game(LOSE_MESSAGE)


## Победа: считаем время забега и обновляем рекорд, если он побит.
func _register_win() -> void:
	var elapsed := _game_timer.wait_time - _game_timer.time_left
	if best_time < 0.0 or elapsed < best_time:
		best_time = elapsed
		_save_best_time()
	_update_hud()


func _end_game(message: String) -> void:
	if game_over:
		return
	game_over = true
	# ВАЖНО: HUD обновляем до stop() — у остановленного таймера time_left == 0.
	_update_hud()
	_game_timer.stop()
	_result_label.text = message
	_play_result_sound(message)
	_message_panel.show()
	_stop_player()
	_stop_enemies()


## Звук под исход партии: победа / поймали / время вышло.
func _play_result_sound(message: String) -> void:
	match message:
		WIN_MESSAGE:
			_sfx_win.play()
		CAUGHT_MESSAGE:
			_sfx_caught.play()
		_:
			_sfx_lose.play()


## Останавливает игрока: обнуляет скорость и выключает физику узла.
func _stop_player() -> void:
	_player.velocity = Vector2.ZERO
	_player.set_physics_process(false)


## Останавливает патруль врагов, чтобы они не ездили по замершей сцене.
func _stop_enemies() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		node.set_process(false)


func _update_hud() -> void:
	_score_label.text = "Счет: %d" % score
	# До старта time_left у остановленного таймера равен 0 — показываем полное время.
	var seconds_left := _game_timer.time_left if _timer_started else _game_timer.wait_time
	_timer_label.text = "Время: %d" % ceili(seconds_left)
	_best_label.text = "Лучшее время: %s" % _format_best_time()


func _format_best_time() -> String:
	if best_time < 0.0:
		return "—"
	return "%.1f сек" % best_time


func _load_best_time() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		best_time = -1.0
		return
	best_time = config.get_value(RECORDS_SECTION, BEST_TIME_KEY, -1.0)


func _save_best_time() -> void:
	var config := ConfigFile.new()
	# Загружаем существующий файл, чтобы не потерять другие секции/ключи.
	config.load(SAVE_PATH)
	config.set_value(RECORDS_SECTION, BEST_TIME_KEY, best_time)
	var err := config.save(SAVE_PATH)
	if err != OK:
		push_warning("Не удалось сохранить рекорд в %s (код %d)" % [SAVE_PATH, err])
