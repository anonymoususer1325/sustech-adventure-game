# save_manager.gd
extends Node

const SAVE_VERSION = 1
const SAVE_PATH = "user://save.dat"   # 存档文件路径

# 保存游戏
func save_game() -> bool:
	var data = collect_save_data()
	var json_string = JSON.stringify(data, "\t")  # 格式化输出，便于调试
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print("无法打开存档文件进行写入")
		return false
	file.store_string(json_string)
	# 可选：保存一份明文校验，或简单加密
	file.close()
	print("游戏已保存至：", SAVE_PATH)
	print("存档实际路径: ", OS.get_user_data_dir() + "/save.dat")
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
	
	return data

# 以下是需要从游戏中获取数据的函数，具体实现取决于你的项目结构
# 暂时可以用示例数据，后续与真实模块对接

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
	var current_scene = get_tree().current_scene
	if current_scene:
		var player = current_scene.get_node_or_null("Player")
		if player:
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
