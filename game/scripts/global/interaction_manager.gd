# scripts/global/interaction_manager.gd
extends Node

# 当前场景中的所有可交互对象（由它们自己注册）
var _interactables: Array[Interactable] = []

# 当前焦点对象
var current_focus: Interactable = null

# 玩家节点引用（需要在游戏场景中设置）
var player: Node2D = null

func _ready():
	# 延迟一帧，确保场景已加载
	await get_tree().process_frame
	# 自动查找玩家（假设玩家节点名为 "Player"）
	if not player:
		var root = get_tree().current_scene
		player = root.get_node_or_null("Player")
		if not player:
			print("警告：未找到玩家节点，请手动设置 InteractionManager.player")

# 注册交互对象（在对象 _ready 时调用）
func register(interactable: Interactable):
	if not _interactables.has(interactable):
		_interactables.append(interactable)
		# 连接其 Area2D 信号（如果存在）
		var area = interactable.get_node_or_null("Area2D")
		if area:
			if not area.body_entered.is_connected(_on_body_entered):
				area.body_entered.connect(_on_body_entered.bind(interactable))
			if not area.body_exited.is_connected(_on_body_exited):
				area.body_exited.connect(_on_body_exited.bind(interactable))

# 注销交互对象（当对象被移除时）
func unregister(interactable: Interactable):
	var idx = _interactables.find(interactable)
	if idx != -1:
		_interactables.remove_at(idx)
	if current_focus == interactable:
		clear_focus()

# 当玩家进入某个交互对象的 Area2D 时
func _on_body_entered(body: Node, interactable: Interactable):
	if body == player:
		# 重新计算焦点（因为可能新进入的对象更近）
		update_focus()

# 当玩家退出时
func _on_body_exited(body: Node, interactable: Interactable):
	if body == player:
		update_focus()

# 更新焦点：找出玩家范围内最近的对象
func update_focus():
	if not player:
		return
	
	var closest: Interactable = null
	var closest_dist_sq: float = INF
	
	for interactable in _interactables:
		# 检查玩家是否在该对象的 Area2D 范围内（但为了精确，也可以直接用距离）
		# 由于我们已经通过 area 信号知道玩家在范围内，但可能存在多个重叠，需要计算实际距离
		var area = interactable.get_node_or_null("Area2D")
		if area and area.overlaps_body(player):
			var dist_sq = _distance_squared(player.global_position, interactable.global_position)
			if dist_sq < closest_dist_sq:
				closest_dist_sq = dist_sq
				closest = interactable
	print("update_focus: 当前焦点=", current_focus.name if current_focus else "null", " 最近对象=", closest.name if closest else "null")
	
	# 设置焦点
	if closest != current_focus:
		print("焦点切换：从 ", current_focus.name if current_focus else "null", " 到 ", closest.name if closest else "null")
		if current_focus:
			current_focus.is_focused = false
		current_focus = closest
		if current_focus:
			current_focus.is_focused = true

# 清除焦点
func clear_focus():
	print("clear_focus 被调用，当前焦点=", current_focus.name if current_focus else "null")
	if current_focus:
		current_focus.is_focused = false
		current_focus = null

# 计算距离的平方（欧氏距离，也可以使用其他距离）
func _distance_squared(a: Vector2, b: Vector2) -> float:
	var dx = a.x - b.x
	var dy = a.y - b.y
	return dx*dx + dy*dy
	# 如果使用切比雪夫距离（用户提到的公式），可改为：
	# return (sqrt(2) * min(abs(dx), abs(dy)) + abs(abs(dx)-abs(dy))) ** 2

# 玩家按下交互键时调用（需要在玩家输入中处理）
func interact_with_focus():
	if current_focus:
		current_focus.interact()
	else:
		print("没有焦点对象")
