extends Node2D

@onready var pause_menu = $PauseMenu

func _ready():
	# 确保暂停菜单初始不可见
	pause_menu.visible = false
	# 连接暂停菜单的自定义信号
	pause_menu.resume_pressed.connect(_on_resume_pressed)
	pause_menu.save_pressed.connect(_on_save_pressed)
	pause_menu.main_menu_pressed.connect(_on_main_menu_pressed)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()

func toggle_pause_menu():
	if pause_menu.visible:
		pause_menu.visible = false
		get_tree().paused = false
	else:
		pause_menu.visible = true
		get_tree().paused = true

func _on_resume_pressed():
	toggle_pause_menu()

func _on_save_pressed():
	# TODO: 后续实现存档功能
	print("保存游戏（暂未实现）")

func _on_main_menu_pressed():
	# 返回主菜单前，必须恢复游戏
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
