extends Area2D

@export var target_scene: String = ""
@export var target_spawn_point: String = ""
@export var marker_color: Color = Color(0.2, 0.6, 1.0, 0.6)

var can_teleport: bool = true
var _player_in_range: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	_generate_marker_sprite()
	 # 延迟一帧后检测玩家是否已在范围内
	call_deferred("_check_player_inside")

func _generate_marker_sprite():
	var sprite = get_node_or_null("TeleportSprite")
	if not sprite:
		return
	# 生成一个半透明彩色方块作为传送门标记
	var size = 32
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(marker_color)
	# 绘制白色边框
	for x in range(size):
		image.set_pixel(x, 0, Color.WHITE)
		image.set_pixel(x, size - 1, Color.WHITE)
		image.set_pixel(0, x, Color.WHITE)
		image.set_pixel(size - 1, x, Color.WHITE)
	# 绘制箭头（指向入口方向）
	for x in range(8, 24):
		var y = x
		image.set_pixel(x, y, Color.WHITE)
		image.set_pixel(size - 1 - x, y, Color.WHITE)
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture

# 延迟检测：解决 monitoring 从 false 切换为 true 时，
# 已在范围内的玩家不会触发 body_entered 的问题
func _check_player_inside():
	if not can_teleport or not monitoring:
		return
	if not InteractionManager or not InteractionManager.player:
		return
	if overlaps_body(InteractionManager.player):
		_on_body_entered(InteractionManager.player)

# 持续检测玩家是否在传送区域内（作为 body_entered 的补充）
func _process(_delta):
	if not can_teleport or not monitoring:
		return
	var player = InteractionManager.player if InteractionManager else null
	if not player:
		return
	var inside = overlaps_body(player)
	if inside and not _player_in_range:
		_player_in_range = true
		_on_body_entered(player)
	elif not inside:
		_player_in_range = false

func _on_body_entered(body: Node):
	if body.name != "Player" or not can_teleport:
		return
	if body != InteractionManager.player:
		return
	
	print("传送触发: ", name, " -> ", target_scene)
	
	# 提前计算所需数据
	var facing = body.facing_direction if "facing_direction" in body else Vector2(0, -1)
	var offset = body.global_position - global_position
	var src_north = SceneManager.current_scene_north
	var target_scene_path = target_scene
	var spawn_point_name = target_spawn_point
	
	can_teleport = false
	_player_in_range = false
	# 锁定玩家移动
	GameState.lock_movement_for(1.0)
	
	var player = body
	
	# 播放缩小动画
	var tween = LightEffectManager.shrink_light(player)
	if tween:
		await tween.finished
	
	# 执行传送
	call_deferred("_perform_teleport", target_scene_path, spawn_point_name, offset, src_north, facing)

func _perform_teleport(target_scene_path: String, spawn_point: String, offset: Vector2, src_north: Vector2, facing: Vector2):
	SceneManager.teleport_to_scene(target_scene_path, spawn_point, offset, src_north, facing)
