# light_effect_manager.gd
extends Node

func get_player_light(player_node: Node) -> Light2D:
	if player_node and player_node.has_node("Circle"):
		return player_node.get_node("Circle")
	return null

# 缩小光源：从最大 -> 停顿缩放 -> 最小
# 参数：
#   player_node: 玩家节点
#   full_scale: 初始最大缩放（默认2.0）
#   pause_scale: 停顿时的缩放（默认0.15）
#   target_scale: 最终最小缩放（默认0.0）
#   duration1: 第一阶段动画时长（秒）
#   duration2: 第二阶段动画时长（秒）
#   pause_duration: 停顿时长（秒）
func shrink_light(player_node: Node, full_scale: float = 2.0, pause_scale: float = 0.15, target_scale: float = 0.0,
				  duration1: float = 0.4, duration2: float = 0.4, pause_duration: float = 0.3) -> Tween:
	var light = get_player_light(player_node)
	if not light:
		return null
	# 确保从全尺寸开始
	light.scale = Vector2(full_scale, full_scale)
	var tween = create_tween()
	# 第一阶段：缩小到 pause_scale
	tween.tween_property(light, "scale", Vector2(pause_scale, pause_scale), duration1)
	# 停顿
	tween.tween_interval(pause_duration)
	# 第二阶段：缩小到 target_scale
	tween.tween_property(light, "scale", Vector2(target_scale, target_scale), duration2)
	return tween

# 扩大光源：从最小 -> 停顿缩放 -> 最大
func expand_light(player_node: Node, full_scale: float = 2.0, pause_scale: float = 0.15, start_scale: float = 0.0,
				  duration1: float = 0.4, duration2: float = 0.4, pause_duration: float = 0.3) -> Tween:
	var light = get_player_light(player_node)
	if not light:
		return null
	# 确保起始缩放为 start_scale
	light.scale = Vector2(start_scale, start_scale)
	var tween = create_tween()
	# 第一阶段：扩大到 pause_scale
	tween.tween_property(light, "scale", Vector2(pause_scale, pause_scale), duration1)
	# 停顿
	tween.tween_interval(pause_duration)
	# 第二阶段：扩大到 full_scale
	tween.tween_property(light, "scale", Vector2(full_scale, full_scale), duration2)
	return tween
