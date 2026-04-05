# scripts/components/interactable.gd
extends Node2D
class_name Interactable

# 交互范围（像素），玩家进入此范围时该对象可成为焦点
@export var interaction_range: float = 72.0

# 焦点高亮效果（可以通过改变 modulate 或添加动画）
@export var highlight_color: Color = Color.YELLOW

# 是否当前为焦点（由管理器设置）
var is_focused: bool = false:
	set(value):
		if is_focused == value:
			return
		is_focused = value
		_update_appearance()

# 原始颜色（用于恢复）
var _original_color: Color = Color.WHITE

# 用于存储玩家的 Sprite 或 Sprite2D 节点（自动查找）
var _sprite: CanvasItem = null

func _ready():
	#print("Interactable _ready: ", name)   # 调试输出
	# 自动查找第一个 Sprite 或 Sprite2D 子节点
	_sprite = _find_sprite()
	if _sprite and _sprite is Sprite2D:
		_original_color = _sprite.modulate
	elif _sprite and _sprite is Sprite2D:
		_original_color = _sprite.modulate
	else:
		# 如果没有精灵，尝试获取父节点的 modulate（可选）
		pass
	# 延迟注册，确保其他节点已就绪
	call_deferred("_register")

func _find_sprite():
	for child in get_children():
		if child is Sprite2D or child is Sprite2D:
			return child
	return null

func _update_appearance():
	if not _sprite:
		return
	if is_focused:
		_sprite.modulate = highlight_color
	else:
		_sprite.modulate = _original_color

# 当玩家交互时调用（由管理器触发）
func interact():
	print("交互对象: ", name)
	# 子类或具体对象可重写此方法，或通过信号发送
	# 例如：触发对话、打开宝箱等

func _register():
	if InteractionManager:
		InteractionManager.register(self)
		print("注册交互对象: ", name)
	else:
		print("错误：InteractionManager 未找到")

func _exit_tree():
	if InteractionManager:
		InteractionManager.unregister(self)
