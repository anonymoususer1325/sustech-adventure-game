# task_data.gd
# 任务数据类，描述一个任务的定义

class_name TaskData

# 字段
var id: String               # 任务ID
var name: String             # 任务名称
var description: String      # 详细描述
var max_progress: int        # 总进度目标
var hidden: bool             # 是否隐藏

func _init(data: Dictionary = {}):
	id = data.get("id", "")
	name = data.get("name", "未知任务")
	description = data.get("description", "")
	max_progress = data.get("max_progress", 1)
	hidden = data.get("hidden", false)

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"max_progress": max_progress,
		"hidden": hidden
	}
