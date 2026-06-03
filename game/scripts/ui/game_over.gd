# game_over.gd
extends Control

func _ready():
	$VBoxContainer/BackToMenuButton.pressed.connect(_on_back_to_menu)

func _on_back_to_menu():
	TaskManager.reset()
	InventoryManager.set_items([])
	GameClock.reset()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
