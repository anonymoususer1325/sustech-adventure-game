extends Node

# 对话数据存储
var _dialogs: Dictionary = {}
var _current_dialog_id: String = ""
var _current_dialog_node: Dictionary = {}
var _current_npc: Node = null

# 信号
signal dialog_started(dialog_data: Dictionary, npc: Node)
signal dialog_updated(dialog_data: Dictionary, npc: Node)
signal dialog_ended()

func _ready():
	load_dialogs("res://data/dialogs.json")

# 加载 JSON 对话文件
func load_dialogs(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		print("错误：对话文件不存在 ", file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		print("JSON 解析失败: ", json.get_error_message())
		return false
	
	var data = json.get_data()
	if data.has("dialogs"):
		_dialogs = data["dialogs"]
		print("成功加载 ", _dialogs.size(), " 个对话节点")
		return true
	else:
		print("JSON 缺少 'dialogs' 根节点")
		return false

# 根据 ID 获取对话节点
func get_dialog_node(dialog_id: String) -> Dictionary:
	return _dialogs.get(dialog_id, {})

# 开始一段对话，需要传入触发对话的 NPC 节点
func start_dialog(dialog_id: String, npc: Node) -> bool:
	if not _dialogs.has(dialog_id):
		print("对话 ID 不存在: ", dialog_id)
		return false
	
	print("对话开始, ID : ", dialog_id)
	_current_dialog_id = dialog_id
	_current_dialog_node = _dialogs[dialog_id]
	_current_npc = npc
	dialog_started.emit(_current_dialog_node, _current_npc)
	return true

# 选择选项（由 UI 调用）
func select_option(option_index: int):
	if _current_dialog_node.is_empty():
		print("没有进行中的对话")
		return
	
	var options = _current_dialog_node.get("options", [])
	if option_index < 0 or option_index >= options.size():
		print("无效的选项索引")
		return
	
	var next_id = options[option_index].get("next_id", "")
	if next_id == "":
		end_dialog()
	else:
		if _dialogs.has(next_id):
			_current_dialog_id = next_id
			_current_dialog_node = _dialogs[next_id]
			dialog_updated.emit(_current_dialog_node, _current_npc)
		else:
			print("后续对话 ID 不存在: ", next_id)
			end_dialog()

# 结束对话
func end_dialog():
	_current_dialog_id = ""
	_current_dialog_node = {}
	_current_npc = null
	dialog_ended.emit()

# 获取当前对话节点（供 UI 查询）
func get_current_dialog_node() -> Dictionary:
	return _current_dialog_node

# 检查是否正在进行对话
func is_dialog_active() -> bool:
	return not _current_dialog_node.is_empty()

# 获取当前 NPC 的显示名称（用于 UI）
func get_current_npc_name() -> String:
	if _current_npc and _current_npc.has_method("get_display_name"):
		return _current_npc.get_display_name()
	return "NPC"
