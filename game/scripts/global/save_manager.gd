# save_manager.gd
extends Node

const SAVE_VERSION = 1
const SAVE_DIR = "user://saves/"
const SAVE_FILENAME = "save_{0}.dat"   # save_0.dat, save_1.dat, ...

var pending_load_data = null   # 允许为 null 或 Vector2

var current_slot: int = -1

func get_save_path(slot: int) -> String:
	return SAVE_DIR + SAVE_FILENAME.format([str(slot)])

# 保存游戏
func save_game(slot: int) -> bool:
	var path = get_save_path(slot)
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
	var data = collect_save_data()
	var json_string = JSON.stringify(data, "\t")  # 格式化输出，便于调试
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("无法打开存档文件进行写入")
		return false
	file.store_string(json_string)
	# 可选：保存一份明文校验，或简单加密
	file.close()
	
	current_slot = slot
	print("游戏已保存")
	print("存档实际路径: ", OS.get_user_data_dir())
	return true
	
func get_user_data_dir() -> String:
	return OS.get_user_data_dir()

# 收集当前游戏状态
func collect_save_data() -> Dictionary:
	var data = {}
	data["version"] = SAVE_VERSION
	
	# 获取当前场景路径（需要实现）
	data["scene_path"] = get_current_scene_path()
	
	# 获取玩家位置（需要实现）
	var player_pos = get_player_position()
	data["player_x"] = player_pos.x
	data["player_y"] = player_pos.y
	
	# 获取已完成任务列表
	data["completed_tasks"] = get_completed_tasks()
	
	# 获取背包物品
	data["inventory"] = get_inventory_items()
	
	# 添加玩家朝向
	var facing = get_player_facing()
	data["facing_x"] = facing.x
	data["facing_y"] = facing.y
	
	# 元数据（需要从游戏管理器获取）
	data["main_quest_progress"] = get_main_quest_progress()
	data["side_quests_completed"] = get_side_quests_completed()
	data["current_focus_task"] = get_current_focus_task()
	data["play_time_seconds"] = get_play_time()
	data["save_time"] = Time.get_datetime_string_from_system()  # 当前系统时间
	
	return data

func get_save_metadata(slot: int) -> Dictionary:
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}   # 空存档
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(content) != OK:
		return {}
	var data = json.get_data()
	# 提取元数据字段，不返回完整游戏状态
	return {
		"exists": true,
		"main_quest_progress": data.get("main_quest_progress", ""),
		"side_quests_completed": data.get("side_quests_completed", 0),
		"current_focus_task": data.get("current_focus_task", ""),
		"play_time_seconds": data.get("play_time_seconds", 0),
		"save_time": data.get("save_time", ""),
		"scene_path": data.get("scene_path", "")  # 可选，用于预览
	}

# 以下是需要从游戏中获取数据的函数，具体实现取决于你的项目结构
# 暂时可以用示例数据，后续与真实模块对接

func get_player_facing() -> Vector2:
	# 优先使用 InteractionManager 中缓存的玩家引用
	if InteractionManager and InteractionManager.player:
		return InteractionManager.player.facing_direction
	# 后备：尝试从当前场景根节点直接查找（兼容旧结构）
	var current_scene = get_tree().current_scene
	if current_scene:
		var player = current_scene.get_node_or_null("Player")
		if player:  # 或直接访问属性
			return player.facing_direction
	return Vector2(0, -1)  # 默认向下

func get_current_scene_path() -> String:
	var current_scene = get_tree().current_scene
	if current_scene:
		# scene_file_path 返回该场景的 .tscn 文件路径
		return current_scene.scene_file_path
	else:
		# 如果没有当前场景，返回一个默认路径（或错误处理）
		print("警告：无法获取当前场景路径")
		return ""

func get_player_position() -> Vector2:
	# 优先使用 InteractionManager 中缓存的玩家引用
	if InteractionManager and InteractionManager.player:
		return InteractionManager.player.global_position
	# 后备：尝试从当前场景根节点直接查找（兼容旧结构）
	var current_scene = get_tree().current_scene
	#print("尝试获取 current scene: ", current_scene)
	if current_scene:
		var player = current_scene.get_node_or_null("Player")
		#print("尝试获取 player: ", player)
		if player:
			#print("player.position: ", player.position)
			return player.position
	return Vector2.ZERO

func get_completed_tasks() -> Array:
	# 示例：从 TaskManager 单例获取
	# 如果 TaskManager 是 autoload，可以直接使用
	if has_node("/root/TaskManager"):
		return get_node("/root/TaskManager").get_completed_tasks()
	return []

func get_inventory_items() -> Array:
	# 示例：从 InventoryManager 获取
	if has_node("/root/InventoryManager"):
		return get_node("/root/InventoryManager").get_items()
	return []

# ========== 占位函数（待任务系统完善后替换） ==========
func get_main_quest_progress() -> String:
	# 模拟主线进度
	return "寻找学生证"

func get_side_quests_completed() -> int:
	# 模拟支线完成数量
	return 0

func get_current_focus_task() -> String:
	# 模拟当前焦点任务
	return "前往图书馆"

# 保存时
func get_play_time() -> float:
	return GameClock.get_total_seconds() if GameClock else 0.0

# save_manager.gd（续）

# 待恢复的存档数据（全局变量，供新场景读取）
var pending_save_data: Dictionary = {}

# 读取存档文件
func load_game(slot: int) -> bool:
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		print("存档文件不存在")
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("无法打开存档文件")
		return false
	
	var file_content = file.get_as_text()
	file.close()
	
	# 如果存档是加密的，先解密
	# var decrypted = simple_decrypt(file_content)   # 若有加密
	
	# 解析 JSON
	var json = JSON.new()
	var error = json.parse(file_content)
	if error != OK:
		print("JSON 解析失败")
		return false
	
	var data = json.get_data()
	
	# 验证版本（可选）
	if data.get("version", 0) != SAVE_VERSION:
		print("存档版本不兼容")
		return false
	
	# 校验和（如果有）
	# 如果有 checksum，验证数据完整性
	
	# 将数据存入待恢复缓存
	pending_save_data = data
	
	# 解析成功后，从 data 字典中获取坐标
	var target_pos = Vector2(data.get("player_x", 0), data.get("player_y", 0))
	var target_facing = Vector2(data.get("facing_x", 0), data.get("facing_y", 1))  # 默认向下
	var play_time = data.get("play_time_seconds", 0.0)   # 获取游玩时长（浮点数）
	
	pending_load_data = {
		"position": target_pos,
		"facing": target_facing,
		"play_time": play_time
	}
	print("load_game: 设置 pending_load_data = ", pending_load_data)
	
	# 切换到存档中的场景
	var scene_path = data.get("scene_path", "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		print("无效的场景路径")
		return false
	
	get_tree().change_scene_to_file(scene_path)
	current_slot = slot
	return true

# 获取并清除待加载位置（由新场景调用）
func consume_pending_load_data():
	var data = pending_load_data
	pending_load_data = null
	return data   # 返回字典或 null

# 获取并清除待恢复数据（供新场景调用）
func consume_pending_save_data() -> Dictionary:
	var data = pending_save_data
	pending_save_data = {}
	return data
