extends Node2D

@onready var pause_menu = $PauseMenu
@onready var player = $Player   # 假设玩家节点在根节点下

func _ready():
	# 确保暂停菜单初始不可见
	pause_menu.visible = false
	# 连接暂停菜单的自定义信号
	pause_menu.resume_pressed.connect(_on_resume_pressed)
	pause_menu.save_pressed.connect(_on_save_pressed)
	pause_menu.main_menu_pressed.connect(_on_main_menu_pressed)
	# 检查是否有待恢复的存档数据
	var save_data = SaveManager.consume_pending_save_data()
	if not save_data.is_empty():
		restore_from_save(save_data)
		
func restore_from_save(data: Dictionary):
	# 恢复玩家位置
	var x = data.get("player_x", 0.0)
	var y = data.get("player_y", 0.0)
	player.position = Vector2(x, y)
	
	# 恢复任务状态
	var completed_tasks = data.get("completed_tasks", [])
	# 假设 TaskManager 有 set_completed_tasks 方法
	TaskManager.set_completed_tasks(completed_tasks)
	
	# 恢复背包物品
	var inventory = data.get("inventory", [])
	InventoryManager.set_inventory(inventory)
	
	print("游戏已从存档恢复")

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
	SaveManager.save_game()
	# 可以显示短暂提示，如 "游戏已保存"
	print("游戏已保存")

func _on_main_menu_pressed():
	# 返回主菜单前，必须恢复游戏
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
