extends Node2D

# 场景的北方向量（默认向上为北）
@export var north_vector: Vector2 = Vector2(0, -1)

@onready var pause_menu = $PauseMenu
@onready var player = $Player   # 假设玩家节点在根节点下

func _ready():
	# 更新场景管理器的北方向量
	SceneManager.current_scene_north = north_vector
	
	# 获取所有传送区域并立即禁用（默认已是false，但确保安全）
	var teleport_areas = get_tree().get_nodes_in_group("teleport_area")
	for area in teleport_areas:
		area.monitoring = false
		print("禁用传送区域: ", area.name)
	
	# 1. 优先处理存档加载（立即恢复位置）
	# --- 存档加载分支 ---
	var load_data = SaveManager.consume_pending_load_data()
	if load_data != null:
		#var player = get_node_or_null("Player")
		if player:
			player.global_position = load_data["position"]
			player.facing_direction = load_data["facing"]
			# 强制更新动画到正确朝向
			player.update_animation(Vector2.ZERO)   # 闲置动画使用最后朝向
			print("从存档恢复位置和朝向: ", load_data["position"], load_data["facing"])
			# 播放扩大动画（如果玩家存在）
			LightEffectManager.expand_light(player)
		GameState.lock_movement_for(0.5)
	
	# 2. 然后处理传送门切换（计算相对偏移）
	var data = SceneManager.consume_pending_teleport_data()
	if not data.is_empty():
		var spawn_point_name = data.get("spawn_point", "")
		var offset = data.get("offset", Vector2.ZERO)
		var src_north = data.get("src_north", Vector2(0, -1))
		var facing = data.get("facing", Vector2(0, -1))   # 默认向下
		
		var spawn_node = get_node_or_null(spawn_point_name)
		if spawn_node is Marker2D:
			var target_north = north_vector
			var rotated_offset = rotate_vector(offset, src_north, target_north)
			var target_pos = spawn_node.global_position + rotated_offset
			#var player = get_node_or_null("Player")
			if player:
				player.global_position = target_pos
				player.facing_direction = facing
				player.update_animation(Vector2.ZERO)   # 强制更新闲置动画
				print("从传送门恢复位置和朝向: ", target_pos, facing)
				# 播放扩大动画
				LightEffectManager.expand_light(player)
		else:
			print("错误：未找到目标生成点 " + spawn_point_name)
		# 锁定玩家 0.5 秒
		GameState.lock_movement_for(0.5)
	
	# 3. 延迟启用所有传送区域（给玩家足够时间稳定）
	await get_tree().create_timer(0.5).timeout
	for area in teleport_areas:
		area.monitoring = true
		#print("恢复传送区域: ", area.name)
	
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

func rotate_vector(vec: Vector2, from_north: Vector2, to_north: Vector2) -> Vector2:
	var from_angle = from_north.angle()
	var to_angle = to_north.angle()
	var angle = to_angle - from_angle
	return vec.rotated(angle)

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
