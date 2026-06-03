extends Node2D

# 场景的北方向量（默认向上为北）
@export var north_vector: Vector2 = Vector2(0, -1)

const COUNTDOWN_SECONDS: float = 600.0  # 10分钟倒计时

var _game_over: bool = false

@onready var pause_menu = $PauseMenu
@onready var player = $YSort/Player

func _ready():
	# 初始化场景管理器
	SceneManager.current_scene_north = north_vector
	
	# 禁用所有传送区域（防止玩家刚出现时误触发）
	var teleport_areas = _disable_teleport_areas()
	
	# 处理存档加载（优先级最高）
	_handle_load_game()
	
	# 处理传送门切换（仅当没有存档加载时）
	_handle_teleport()
	
	# 设置交互管理器玩家引用
	_setup_interaction_manager()
	
	# 设置暂停菜单
	_setup_pause_menu()
	
	# 延迟启用传送区域（给玩家稳定时间）
	_enable_teleport_areas(teleport_areas)
	
	# 处理自动开始任务
	_handle_auto_start_tasks()
	
	# 设置任务相关信号连接
	_setup_task_signals()

# ========== 辅助方法 ==========
func _disable_teleport_areas() -> Array:
	var areas = get_tree().get_nodes_in_group("teleport_area")
	for area in areas:
		area.monitoring = false
		print("禁用传送区域: ", area.name)
	return areas

func _enable_teleport_areas(areas: Array):
	await get_tree().create_timer(0.5).timeout
	for area in areas:
		area.monitoring = true
		print("恢复传送区域: ", area.name)

var _loaded_from_save: bool = false

func _handle_load_game():
	var load_data = SaveManager.consume_pending_load_data()
	if load_data == null:
		return
	
	_loaded_from_save = true
	
	if player:
		player.global_position = load_data["position"]
		player.facing_direction = load_data["facing"]
		player.update_animation(Vector2.ZERO)
		print("从存档恢复位置和朝向: ", load_data["position"], load_data["facing"])
		
		# 恢复游玩时长
		var play_time = load_data.get("play_time", 0.0)
		GameClock.restore_time(play_time)
		print("从存档恢复游玩时长: ", play_time)
		
		LightEffectManager.expand_light(player)
	GameState.lock_movement_for(0.5)

func _handle_teleport():
	var data = SceneManager.consume_pending_teleport_data()
	if data.is_empty():
		# 没有传送数据，启动游戏时钟（正常开始游戏）
		GameClock.start()
		return
	
	var spawn_point_name = data.get("spawn_point", "")
	var offset = data.get("offset", Vector2.ZERO)
	var src_north = data.get("src_north", Vector2(0, -1))
	var facing = data.get("facing", Vector2(0, -1))
	
	var spawn_node = get_node_or_null(spawn_point_name)
	if spawn_node is Marker2D:
		var target_north = north_vector
		var rotated_offset = _rotate_vector(offset, src_north, target_north)
		var target_pos = spawn_node.global_position + rotated_offset
		if player:
			player.global_position = target_pos
			player.facing_direction = facing
			player.update_animation(Vector2.ZERO)
			print("从传送门恢复位置和朝向: ", target_pos, facing)
			LightEffectManager.expand_light(player)
	else:
		print("错误：未找到目标生成点 ", spawn_point_name)
	
	GameState.lock_movement_for(0.5)

var _tasks_initialized: bool = false

func _handle_auto_start_tasks():
	if _tasks_initialized:
		return
	_tasks_initialized = true
	
	# 只有新游戏才自动启动起始任务，读档时不做
	if not _loaded_from_save:
		if TaskManager.get_task_status("gather_supplies") == TaskManager.TaskStatus.NOT_STARTED:
			TaskManager.start_task("gather_supplies")
	
	# 确保至少有一个焦点任务
	if TaskManager.get_focus_task_id().is_empty():
		var in_progress = TaskManager.get_in_progress_tasks()
		if not in_progress.is_empty():
			TaskManager.toggle_focus_task(in_progress[0])

func _setup_interaction_manager():
	if player:
		InteractionManager.player = player
		print("InteractionManager 玩家已设置: ", player.name)
	else:
		print("警告：未找到玩家节点，无法设置 InteractionManager.player")

func _setup_pause_menu():
	pause_menu.visible = false
	pause_menu.resume_pressed.connect(_on_resume_pressed)
	pause_menu.main_menu_pressed.connect(_on_main_menu_pressed)
	# 可选：连接保存信号（如果暂停菜单中有保存按钮）
	# pause_menu.save_pressed.connect(_on_save_pressed)

func _rotate_vector(vec: Vector2, from_north: Vector2, to_north: Vector2) -> Vector2:
	var from_angle = from_north.angle()
	var to_angle = to_north.angle()
	var angle = to_angle - from_angle
	return vec.rotated(angle)

# ========== 游戏状态恢复（暂未使用，保留） ==========
func restore_from_save(data: Dictionary):
	if not player:
		return
	player.position = Vector2(data.get("player_x", 0.0), data.get("player_y", 0.0))
	TaskManager.set_completed_tasks(data.get("completed_tasks", []))
	InventoryManager.set_inventory(data.get("inventory", []))
	print("游戏已从存档恢复")

# ========== 输入处理 ==========
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		# 如果任务UI打开，优先关闭
		var task_ui = _get_task_ui_node()
		if task_ui and task_ui.visible:
			task_ui.close()
			return
		# 如果背包打开，优先关闭背包
		var backpack = _get_backpack()
		if backpack and backpack.visible:
			backpack.close()
			return
		toggle_pause_menu()

func toggle_pause_menu():
	if pause_menu.visible:
		pause_menu.visible = false
		get_tree().paused = false
		GameClock.start()
	else:
		pause_menu.visible = true
		get_tree().paused = true
		GameClock.pause()

# ========== 暂停菜单信号处理 ==========
func _on_resume_pressed():
	toggle_pause_menu()

func _on_save_pressed():
	# 保存到第一个存档位（可根据需要调整）
	SaveManager.save_game(0)
	print("游戏已保存")

func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

# 获取背包UI节点
func _get_backpack():
	var layer = get_node_or_null("BackpackLayer")
	if layer:
		return layer.get_node_or_null("BackpackUI")
	return null

# 获取任务UI节点
func _get_task_ui_node():
	var layer = get_node_or_null("TaskLayer")
	if layer:
		return layer.get_node_or_null("TaskUI")
	return null

# ========== 任务链信号设置 ==========
func _setup_task_signals():
	if TaskManager.task_completed.is_connected(_on_task_completed_chain):
		TaskManager.task_completed.disconnect(_on_task_completed_chain)
	TaskManager.task_completed.connect(_on_task_completed_chain)
	
	if InventoryManager.inventory_updated.is_connected(_on_inventory_updated_check):
		InventoryManager.inventory_updated.disconnect(_on_inventory_updated_check)
	InventoryManager.inventory_updated.connect(_on_inventory_updated_check)

# ========== 倒计时 ==========
func _process(_delta):
	if _game_over:
		return
	if get_tree().paused:
		return
	
	var remaining = COUNTDOWN_SECONDS - GameClock.get_total_seconds()
	if remaining <= 0:
		_game_over = true
		_show_game_over()

func get_remaining_time() -> float:
	return max(0, COUNTDOWN_SECONDS - GameClock.get_total_seconds())

# ========== 任务链信号方法 ==========

# 任务完成链
func _on_task_completed_chain(task_id: String):
	match task_id:
		"gather_supplies":
			if TaskManager.get_task_status("deliver_to_teaching") == TaskManager.TaskStatus.NOT_STARTED:
				TaskManager.start_task("deliver_to_teaching")
				print("新任务: 将物资送到教学楼")
		"deliver_to_teaching":
			print("全部任务完成！通关！")
			_show_game_complete()

# 实时监测物品收集进度
func _on_inventory_updated_check():
	if TaskManager.get_task_status("gather_supplies") == TaskManager.TaskStatus.IN_PROGRESS:
		var progress = 0
		if InventoryManager.has_item("student_card"):
			progress += 1
		if InventoryManager.has_item("library_card"):
			progress += 1
		if InventoryManager.has_item("note"):
			progress += 1
		if InventoryManager.has_item("pencil"):
			progress += 1
		TaskManager.update_progress("gather_supplies", progress)

# 显示通关画面
func _show_game_complete():
	call_deferred("_deferred_switch_scene", "res://scenes/ui/game_complete.tscn")

func _show_game_over():
	call_deferred("_deferred_switch_scene", "res://scenes/ui/game_over.tscn")

func _deferred_switch_scene(scene_path: String):
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
