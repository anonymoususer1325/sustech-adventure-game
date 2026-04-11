# inventory_manager.gd
extends Node

# 存储物品列表，每个物品为 { "id": String, "count": int }
var items: Array = []

func set_inventory(inv: Array):
	items = inv.duplicate()
	# 更新背包 UI

# 获取物品列表（供存档使用）
func get_items() -> Array:
	return items.duplicate(true)  # 深拷贝，确保字典也复制

# 设置物品列表（供读档使用）
func set_items(new_items: Array):
	items = new_items.duplicate(true)

# 添加物品
func add_item(item_id: String, count: int = 1):
	# 查找是否已有
	for i in range(items.size()):
		if items[i]["id"] == item_id:
			items[i]["count"] += count
			return
	# 不存在则新增
	items.append({"id": item_id, "count": count})

# 移除物品（可选）
func remove_item(item_id: String, count: int = 1):
	for i in range(items.size()):
		if items[i]["id"] == item_id:
			items[i]["count"] -= count
			if items[i]["count"] <= 0:
				items.remove_at(i)
			return

func reset():
	items.clear()
