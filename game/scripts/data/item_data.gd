# item_data.gd
# 物品数据结构定义
# 每个物品由以下字段描述：
#   id:          String  - 唯一标识符
#   name:        String  - 显示名称
#   description: String  - 描述文本
#   icon_path:   String  - 图标资源路径
#   stackable:   bool    - 是否可堆叠
#   max_stack:   int     - 最大堆叠数量
#   use_effect:  String  - 使用效果标识（空字符串表示不可使用）
#   use_effect_params: Dictionary - 使用效果参数

class_name ItemData

# 字段
var id: String
var name: String
var description: String
var icon_path: String
var stackable: bool
var max_stack: int
var use_effect: String
var use_effect_params: Dictionary

# 从字典构造
func _init(data: Dictionary = {}):
	id = data.get("id", "")
	name = data.get("name", "未知物品")
	description = data.get("description", "")
	icon_path = data.get("icon_path", "")
	stackable = data.get("stackable", true)
	max_stack = data.get("max_stack", 99)
	use_effect = data.get("use_effect", "")
	use_effect_params = data.get("use_effect_params", {})

# 检查是否可以使用
func is_usable() -> bool:
	return use_effect != ""

# 获取图标路径（返回可用的 Texture2D，如果图标不存在则返回 null）
func get_icon() -> Texture2D:
	if icon_path.is_empty():
		return null
	return load(icon_path) as Texture2D

# 转换为字典（用于存档序列化）
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"icon_path": icon_path,
		"stackable": stackable,
		"max_stack": max_stack,
		"use_effect": use_effect,
		"use_effect_params": use_effect_params.duplicate()
	}
