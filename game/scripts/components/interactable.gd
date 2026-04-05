# scripts/components/interactable.gd
extends Node2D
class_name Interactable

# 交互范围（像素），玩家进入此范围时该对象可成为焦点
@export var interaction_range: float = 72.0

# 是否当前为焦点（由管理器设置）
var is_focused: bool = false:
	set(value):
		if is_focused == value:
			return
		is_focused = value
		# 直接调用自身的虚方法
		_on_focus_changed(is_focused)

# 用于存储玩家的 Sprite 或 Sprite2D 节点（自动查找）
var _sprite: CanvasItem = null

func _ready():
	# 延迟注册，确保其他节点已就绪
	call_deferred("_register")

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

func _on_focus_changed(focused: bool):
	print("警告：使用了未被重写的_on_focus_changed方法 (Interactable)")
