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

# save_manager.gd（续）

# 待恢复的存档数据（全局变量，供新场景读取）
var pending_save_data: Dictionary = {}

# 读取存档文件
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("存档文件不存在")
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
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
	
	# 切换到存档中的场景
	var scene_path = data.get("scene_path", "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		print("无效的场景路径")
		return false
	
	get_tree().change_scene_to_file(scene_path)
	return true

# 获取并清除待恢复数据（供新场景调用）
func consume_pending_save_data() -> Dictionary:
	var data = pending_save_data
	pending_save_data = {}
	return data
