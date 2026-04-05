extends Interactable

@export var default_direction: String = "down"

@onready var animation = $NpcAnimatedSprite

func _ready():
	super._ready()
	update_animation(default_direction)

# 重写焦点变化回调
func _on_focus_changed(focused: bool):
	print("NPC _on_focus_changed: ", focused)   # 调试
	if focused:
		print("Execute on focus changed: focused")
		var player = InteractionManager.player
		if player:
			var dir = get_direction_to_player(player.global_position)
			update_animation(dir)
	else:
		print("Execute on focus changed: defocused")
		update_animation(default_direction)

func _process(delta):
	# 使用父类的 is_focused 属性（通过 getter）
	if is_focused:
		var player = InteractionManager.player
		if player:
			var dir = get_direction_to_player(player.global_position)
			update_animation(dir)

func get_direction_to_player(player_pos: Vector2) -> String:
	var delta = player_pos - global_position
	if abs(delta.x) > abs(delta.y):
		return "right" if delta.x > 0 else "left"
	else:
		return "down" if delta.y > 0 else "up"

func update_animation(direction: String):
	#print("update_animation: is_focused=", is_focused)   # 调试
	var prefix = "focus_" if is_focused else "idle_"
	var anim_name = prefix + direction
	if animation.sprite_frames.has_animation(anim_name):
		animation.play(anim_name)
	else:
		animation.play("idle_" + direction)
