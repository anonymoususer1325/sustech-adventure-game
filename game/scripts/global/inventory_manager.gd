# inventory_manager.gd
# 背包物品管理单例（Autoload）
# 负责：
#   - 加载和管理物品定义（items.json）
#   - 增删查改玩家背包中的物品
#   - 发射 inventory_updated 信号供 UI 刷新
#   - 提供物品使用接口

extends Node

# ======================== 信号 ========================
# 背包内容发生变化时发射，供 UI 等模块监听刷新
signal inventory_updated()

# ======================== 常量 ========================
const ITEMS_DATA_PATH: String = "res://data/items.json"

# ======================== 物品定义 ========================
# 存储所有物品的定义数据，键为物品 ID，值为 ItemData 实例
var _item_definitions: Dictionary = {}

# ======================== 背包存储 ========================
# 存储物品列表，每个元素为 { "id": String, "count": int }
var items: Array = []

# ======================== 初始化 ========================
func _ready():
	_load_item_definitions()

# 从 JSON 文件加载物品定义
func _load_item_definitions():
	if not FileAccess.file_exists(ITEMS_DATA_PATH):
		push_error("物品定义文件不存在: ", ITEMS_DATA_PATH)
		return
	
	var file = FileAccess.open(ITEMS_DATA_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		push_error("物品定义 JSON 解析失败: ", json.get_error_message())
		return
	
	var data = json.get_data()
	if not data.has("items"):
		push_error("物品定义 JSON 缺少 'items' 根节点")
		return
	
	var raw_items = data["items"]
	for item_id in raw_items.keys():
		var item_dict = raw_items[item_id]
		item_dict["id"] = item_id  # 确保 ID 一致
		_item_definitions[item_id] = ItemData.new(item_dict)
	
	print("成功加载 ", _item_definitions.size(), " 个物品定义")

# ======================== 物品定义查询 ========================

# 获取某个物品的定义数据，若无定义则返回 null
func get_item_data(item_id: String) -> ItemData:
	return _item_definitions.get(item_id, null)

# 获取所有物品定义（键为物品 ID，值为 ItemData）
func get_all_item_definitions() -> Dictionary:
	return _item_definitions.duplicate()

# 判断某物品 ID 是否有定义
func has_item_definition(item_id: String) -> bool:
	return _item_definitions.has(item_id)

# ======================== 背包操作 ========================

# 获取物品列表副本（供存档使用）
func get_items() -> Array:
	return items.duplicate(true)

# 设置物品列表（供读档使用）
func set_items(new_items: Array):
	items = new_items.duplicate(true)
	inventory_updated.emit()

# （向后兼容）设置背包（旧接口）
func set_inventory(inv: Array):
	set_items(inv)

# 添加物品
# 如果物品可堆叠，会累加到已有堆叠中；否则新增一个条目
func add_item(item_id: String, count: int = 1):
	if count <= 0:
		return
	
	var def = _item_definitions.get(item_id)
	if def == null:
		push_warning("添加未定义的物品: ", item_id)
		# 仍然允许添加，使用默认行为
		
	if def and not def.stackable:
		# 不可堆叠：每次添加一个独立条目（但一般只允许持有一个）
		for i in range(count):
			items.append({"id": item_id, "count": 1})
	else:
		var max_stack = def.max_stack if def else 99
		var remaining = count
		for i in range(items.size()):
			if items[i]["id"] == item_id:
				var space = max_stack - items[i]["count"]
				if space > 0:
					var to_add = min(remaining, space)
					items[i]["count"] += to_add
					remaining -= to_add
					if remaining <= 0:
						inventory_updated.emit()
						return
		# 还有剩余，新增一条
		while remaining > 0:
			var to_add = min(remaining, max_stack)
			items.append({"id": item_id, "count": to_add})
			remaining -= to_add
	
	inventory_updated.emit()

# 移除物品
# 返回实际移除的数量
func remove_item(item_id: String, count: int = 1) -> int:
	if count <= 0:
		return 0
	
	var removed = 0
	var i = 0
	while i < items.size() and removed < count:
		if items[i]["id"] == item_id:
			var can_remove = min(items[i]["count"], count - removed)
			items[i]["count"] -= can_remove
			removed += can_remove
			if items[i]["count"] <= 0:
				items.remove_at(i)
				# 不递增 i，因为 remove_at 后后面的元素前移
			else:
				i += 1
		else:
			i += 1
	
	if removed > 0:
		inventory_updated.emit()
	return removed

# 获取某物品的持有数量
func get_item_count(item_id: String) -> int:
	var total = 0
	for entry in items:
		if entry["id"] == item_id:
			total += entry["count"]
	return total

# 判断是否持有某物品（数量 > 0）
func has_item(item_id: String) -> bool:
	return get_item_count(item_id) > 0

# 使用物品
# 返回 true 表示使用成功，false 表示失败
func use_item(item_id: String, count: int = 1) -> bool:
	if not has_item(item_id):
		push_warning("尝试使用不拥有的物品: ", item_id)
		return false
	
	var def = get_item_data(item_id)
	if def == null:
		push_warning("使用未定义的物品: ", item_id)
		return false
	
	if not def.is_usable():
		push_warning("物品不可使用: ", item_id)
		return false
	
	# 移除物品
	var removed = remove_item(item_id, count)
	if removed <= 0:
		return false
	
	# 触发使用效果（由具体游戏逻辑实现，这里发射信号或调用全局方法）
	_apply_use_effect(item_id, def.use_effect, def.use_effect_params)
	
	return true

# 应用使用效果（可被子类重写或由外部系统监听）
func _apply_use_effect(item_id: String, effect: String, params: Dictionary):
	match effect:
		"heal":
			print("使用物品 [", item_id, "] 恢复生命，参数: ", params)
		"speed_up":
			print("使用物品 [", item_id, "] 加速，参数: ", params)
		"unlock_area":
			print("使用物品 [", item_id, "] 解锁区域，参数: ", params)
		"unlock_door":
			print("使用物品 [", item_id, "] 解锁门，参数: ", params)
		"read_message":
			print("使用物品 [", item_id, "] 阅读信息，参数: ", params)
		"add_time":
			var seconds = params.get("seconds", 60)
			GameClock.add_time(seconds)
			print("使用物品 [", item_id, "] 增加时间 +", seconds, "秒")
		"open_mail":
			print("使用物品 [", item_id, "] 打开邮件，参数: ", params)
		"reveal_map":
			print("使用物品 [", item_id, "] 显示地图，参数: ", params)
		"become_invisible":
			print("使用物品 [", item_id, "] 隐身，参数: ", params)
		_:
			print("使用物品 [", item_id, "] 未知效果: ", effect)

# 清空背包
func reset():
	items.clear()
	inventory_updated.emit()

# 获取所有物品的类型数量（不同物品的种类数）
func get_item_type_count() -> int:
	return items.size()

# 获取背包中所有物品的总数量
func get_total_item_count() -> int:
	var total = 0
	for entry in items:
		total += entry["count"]
	return total

# 检查背包是否为空
func is_empty() -> bool:
	return items.is_empty()
