extends CharacterBody2D

# 移动速度（像素/秒）
@export var speed: float = 300.0

func _physics_process(delta: float) -> void:
	# 获取输入轴（-1 ~ 1）
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 斜向移动时自动归一化，保证速度一致
	# get_vector 已经返回归一化后的方向，无需额外处理
	var direction := input_dir
	
	# 设置速度
	velocity = direction * speed
	
	# 移动并处理碰撞
	move_and_slide()
