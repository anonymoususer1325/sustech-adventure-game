# game_clock.gd
extends Node

var _total_seconds: float = 0.0
var _is_running: bool = true

func _process(delta: float):
	if _is_running:
		_total_seconds += delta

func start():
	_is_running = true

func pause():
	_is_running = false

func reset():
	_total_seconds = 0.0

func get_total_seconds() -> float:
	return _total_seconds

func set_total_seconds(seconds: float):
	_total_seconds = seconds
