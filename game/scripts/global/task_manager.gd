# task_manager.gd
extends Node

# 存储已完成任务的ID列表
var completed_tasks: Array = []

# 获取已完成任务列表（供存档使用）
func get_completed_tasks() -> Array:
	return completed_tasks.duplicate()  # 返回副本，避免外部修改

# 设置已完成任务列表（供读档使用）
func set_completed_tasks(tasks: Array):
	completed_tasks = tasks.duplicate()
	# 可以发射信号，通知UI更新
	# completed_tasks_changed.emit()

# 标记任务完成
func complete_task(task_id: String):
	if not completed_tasks.has(task_id):
		completed_tasks.append(task_id)
		# 可选：发射信号
