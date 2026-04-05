extends CharacterBody2D

# 移动速度
@export var walk_speed: float = 200.0
@export var run_speed: float = 320.0   # 1.6倍行走速度

# 当前实际速度
var current_speed: float = walk_speed
# 奔跑状态
var is_running: bool = false
# 外观方向（单位向量，只取上下左右）
var facing_direction: Vector2 = Vector2.DOWN

# 动画节点
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# 确保初始动画正确
	update_animation(Vector2.ZERO)

func _physics_process(_delta: float) -> void:
		# 移动锁定检查
	if GameState.movement_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# 正常移动逻辑
	# 获取输入方向（八方向）
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = input_dir
	
	# 检测奔跑按键
	is_running = Input.is_action_pressed("run")
	current_speed = run_speed if is_running else walk_speed
	
	# 设置速度
	velocity = direction * current_speed
	move_and_slide()
	
	# 更新外观方向（仅轴向移动时更新）
	update_facing_direction(direction)
	
	# 更新动画
	update_animation(direction)

func update_facing_direction(direction: Vector2):
	if direction.length() > 0.1:
		var is_diagonal = abs(direction.x) > 0.1 and abs(direction.y) > 0.1
		if not is_diagonal:
			# 轴向移动，直接更新外观方向
			facing_direction = direction.normalized()
		else:
			# 斜向移动：检查外观方向与运动方向是否成钝角（点积 < 0）
			if facing_direction.dot(direction) < 0:
				# 重置为水平方向（左或右）
				facing_direction = Vector2(sign(direction.x), 0)

func update_animation(direction: Vector2):
	var is_moving = direction.length() > 0.1
	if is_moving:
		# 播放移动动画（行走或奔跑）
		var anim_prefix = "run_" if is_running else "walk_"
		var anim_name = anim_prefix + get_direction_string(facing_direction)
		animated_sprite.play(anim_name)
	else:
		# 播放闲置动画
		var idle_name = "idle_" + get_direction_string(facing_direction)
		animated_sprite.play(idle_name)

func get_direction_string(dir: Vector2) -> String:
	# 根据向量返回方向字符串（用于动画名称）
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"

# 在 player.gd 中添加一个测试输入
#func _input(event):
	#if event.is_action_pressed("ui_test"):  # 需在输入映射中添加一个测试动作
		#print("触发测试事件：设置尺寸为 (2, 2)")
		#$Circle.scale = Vector2(2, 2)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		InteractionManager.interact_with_focus()
