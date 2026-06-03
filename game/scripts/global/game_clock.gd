# game_clock.gd
extends Node

var _start_ms: int = 0
var _paused_ms: int = 0
var _is_running: bool = true
var _pause_start_ms: int = 0

func _ready():
	_start_ms = Time.get_ticks_msec()

func reset():
	_start_ms = Time.get_ticks_msec()
	_paused_ms = 0
	_is_running = true

func start():
	if not _is_running:
		_paused_ms += Time.get_ticks_msec() - _pause_start_ms
	_is_running = true

func pause():
	_is_running = false
	_pause_start_ms = Time.get_ticks_msec()

func get_total_seconds() -> float:
	if _is_running:
		return float(Time.get_ticks_msec() - _start_ms - _paused_ms) / 1000.0
	else:
		return float(_pause_start_ms - _start_ms - _paused_ms) / 1000.0

func add_time(seconds: float):
	_paused_ms += int(seconds * 1000)

func restore_time(seconds: float):
	_paused_ms = 0
	_start_ms = Time.get_ticks_msec() - int(seconds * 1000)
