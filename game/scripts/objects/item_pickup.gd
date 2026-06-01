# item_pickup.gd
# 场景中可拾取的物品对象
# 继承 Interactable，利用现有交互系统。
# 玩家靠近后按确认键(ui_accept)拾取物品。

extends Interactable

# ======================== 导出变量 ========================
# 物品ID（与 items.json 中的 id 对应）
@export var item_id: String = "lychee"
# 拾取数量
@export var item_count: int = 1
# 拾取后是否消失（一次性物品）
@export var disappear_on_pickup: bool = true
# 是否可重复拾取
@export var repeatable: bool = false

# ======================== 节点引用 ========================
@onready var sprite: Sprite2D = $ItemSprite
@onready var pickup_label: Label = $PickupPrompt
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 内部状态
var _collected: bool = false

# ======================== 颜色映射 ========================
# 为每种物品分配一个独特的颜色，用于占位图标
const ITEM_COLORS: Dictionary = {
	"student_card": Color(0.9, 0.7, 0.2),
	"phone": Color(0.3, 0.6, 0.9),
	"radar": Color(0.2, 0.8, 0.4),
	"lychee": Color(0.9, 0.3, 0.3),
	"library_card": Color(0.6, 0.4, 0.8),
	"key": Color(0.8, 0.7, 0.3),
	"note": Color(0.9, 0.9, 0.5),
	"speed_boost": Color(0.2, 0.9, 0.9),
	"invisibility": Color(0.6, 0.6, 0.9),
}

func _ready():
	super._ready()
	if pickup_label:
		pickup_label.visible = false
	
	# 生成占位图标（优先加载真实图标，否则用彩色几何图形）
	_update_sprite()
	
	# 延迟一帧后强制刷新焦点，解决初始重叠时信号不触发的问题
	call_deferred("_refresh_focus")

# 强制刷新 InteractionManager 的焦点
func _refresh_focus():
	if InteractionManager:
		InteractionManager.update_focus()

# 更新精灵外观：尝试加载真实图标，失败则生成彩色占位图
func _update_sprite():
	if not sprite:
		return
	
	var item_data = InventoryManager.get_item_data(item_id)
	
	# 优先尝试加载真实图标
	if item_data and not item_data.icon_path.is_empty():
		var tex = load(item_data.icon_path) as Texture2D
		if tex:
			sprite.texture = tex
			sprite.self_modulate = Color.WHITE
			return
	
	# 生成占位图标：彩色方块 + 物品首字母
	_generate_placeholder_sprite(item_data)

# 生成彩色方块占位图标（后续替换为美术资源即可）
func _generate_placeholder_sprite(item_data: ItemData):
	var size = 32
	var color = ITEM_COLORS.get(item_id, Color(0.5, 0.5, 0.5))
	
	# 创建 Image 并绘制彩色方块
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	
	# 绘制边框
	for x in range(size):
		image.set_pixel(x, 0, Color.WHITE)
		image.set_pixel(x, size - 1, Color.WHITE)
		image.set_pixel(0, x, Color.WHITE)
		image.set_pixel(size - 1, x, Color.WHITE)
	
	# 转换为纹理
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	sprite.self_modulate = Color.WHITE
	sprite.scale = Vector2(1.5, 1.5)

# ======================== 区域检测（用于显示提示） ========================
# 使用实时 overlap 检测替代信号，避免初始重叠时信号不触发的问题
func _is_player_in_range() -> bool:
	if not InteractionManager or not InteractionManager.player:
		return false
	if _collected and not repeatable:
		return false
	return $Area2D.overlaps_body(InteractionManager.player)

# 更新拾取提示的可见性
func _update_prompt_visibility():
	if not pickup_label:
		return
	
	if _collected and not repeatable:
		pickup_label.visible = false
		return
	
	var item_data = InventoryManager.get_item_data(item_id)
	var item_name = item_data.name if item_data else item_id
	
	if _is_player_in_range() and is_focused and not _collected:
		pickup_label.text = "拾取 " + item_name + " [E/Space]"
		pickup_label.visible = true
	else:
		pickup_label.visible = false

# ======================== 每帧更新 ========================
# 持续检测玩家距离，更新提示可见性
func _process(_delta):
	_update_prompt_visibility()

# ======================== 焦点变化 ========================
func _on_focus_changed(focused: bool):
	_update_prompt_visibility()

# ======================== 交互（拾取） ========================
func interact():
	super.interact()
	
	if _collected and not repeatable:
		print("物品已被拾取: ", item_id)
		return
	
	if _is_player_in_range():
		_pickup()

# 实际拾取逻辑
func _pickup():
	print("拾取物品: ", item_id, " x", item_count)
	
	# 添加到背包
	InventoryManager.add_item(item_id, item_count)
	
	# 播放拾取效果
	if animation_player and animation_player.has_animation("pickup"):
		animation_player.play("pickup")
	
	# 可选：播放音效
	# if SoundManager:
	#     SoundManager.play_sound("pickup")
	
	if disappear_on_pickup and not repeatable:
		_collected = true
		# 隐藏精灵和碰撞体
		if sprite:
			sprite.visible = false
		if $Area2D:
			$Area2D.monitoring = false
			$Area2D.monitorable = false
		if pickup_label:
			pickup_label.visible = false
		# 用计时器延迟释放（让动画播完）
		await get_tree().create_timer(0.3).timeout
		queue_free()
