extends Area2D

@export var target_scene: String = ""
@export var target_spawn_point: String = ""

var can_teleport: bool = true

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if body.name != "Player" or not can_teleport:
		return
	
	# 提前计算所需数据
	var facing = body.facing_direction
	var offset = body.global_position - global_position
	var src_north = SceneManager.current_scene_north
	var target_scene_path = target_scene
	var spawn_point_name = target_spawn_point
	
	can_teleport = false
	# 锁定玩家移动（防止动画期间移动）
	GameState.lock_movement_for(1.0)   # 锁定足够长时间（覆盖动画+传送）
	
	# 获取玩家节点
	var player = body
	
	# 播放缩小动画
	var tween = LightEffectManager.shrink_light(player)
	if tween:
		await tween.finished
	
	# 可选：微小延迟确保视觉效果完整（例如0.05秒）
	#await get_tree().create_timer(0.05).timeout
	
	# 执行传送（场景切换）
	call_deferred("_perform_teleport", target_scene_path, spawn_point_name, offset, src_north, facing)
	
	# 注意：传送后当前场景会被销毁，因此后面的代码不会执行。
	# 传送后，目标场景的 _ready 中会播放扩大动画。

func _perform_teleport(target_scene_path: String, spawn_point: String, offset: Vector2, src_north: Vector2, facing: Vector2):
	SceneManager.teleport_to_scene(target_scene_path, spawn_point, offset, src_north, facing)
