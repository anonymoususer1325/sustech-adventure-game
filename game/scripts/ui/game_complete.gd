# game_complete.gd
# 通关画面：显示游玩时间、完成任务数，提供返回主菜单和继续探索的选项

extends Control

@onready var play_time_label = $VBoxContainer/PlayTimeRow/PlayTimeValue
@onready var tasks_completed_label = $VBoxContainer/TasksRow/TasksCompletedValue
@onready var back_to_menu_btn = $VBoxContainer/BackToMenuButton

func _ready():
	# 显示通关信息
	var play_time = GameClock.get_total_seconds()
	play_time_label.text = _format_time(play_time)
	
	# 计算完成任务数
	var completed_count = TaskManager.get_completed_tasks().size()
	var total_count = TaskManager.get_all_task_definitions().size()
	tasks_completed_label.text = str(completed_count) + " / " + str(total_count)
	
	# 连接按钮
	back_to_menu_btn.pressed.connect(_on_back_to_menu)
	
	# 也提供一个继续探索的按钮（可选）
	var continue_btn = $VBoxContainer/ContinueButton
	if continue_btn:
		continue_btn.pressed.connect(_on_continue_exploring)

func _format_time(total_seconds: float) -> String:
	var hours = int(total_seconds) / 3600
	var minutes = (int(total_seconds) % 3600) / 60
	var seconds = int(total_seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func _on_back_to_menu():
	# 重置游戏状态
	TaskManager.reset()
	InventoryManager.set_items([])
	GameClock.reset()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_continue_exploring():
	# 继续探索：回到最后所在的场景
	get_tree().change_scene_to_file("res://scenes/levels/campus_LH3_sou.tscn")
