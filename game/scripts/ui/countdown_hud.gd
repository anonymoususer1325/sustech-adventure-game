# countdown_hud.gd
extends Control

@onready var time_label: Label = $Background/TimeLabel

func _process(_delta):
	if not time_label:
		return
	var elapsed = GameClock.get_total_seconds()
	var remaining = max(0, 600.0 - elapsed)
	var m = int(remaining) / 60
	var s = int(remaining) % 60
	time_label.text = "⏱ %02d:%02d" % [m, s]
	time_label.modulate = Color.RED if remaining <= 60 else Color.WHITE
