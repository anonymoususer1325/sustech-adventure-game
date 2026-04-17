# game_state.gd
extends Node

# 移动锁定标志（true = 玩家无法移动）
var movement_locked: bool = false
var is_dialog_active: bool = false #对话是否激活

# 锁定玩家并设置延迟解锁（时间秒）
func lock_movement_for(duration: float):
	movement_locked = true
	# 使用 SceneTree 的 create_timer，注意在当前场景中调用
	get_tree().create_timer(duration).timeout.connect(func():
		movement_locked = false
		print("移动锁定解除")
	)
