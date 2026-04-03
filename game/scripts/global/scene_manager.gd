extends Node

var current_scene_north: Vector2 = Vector2(0, -1)
var pending_teleport_data: Dictionary = {}   # 存储待传送的数据

func teleport_to_scene(target_scene_path: String, spawn_point_name: String, offset: Vector2, src_north: Vector2, facing: Vector2):
	pending_teleport_data = {
		"spawn_point": spawn_point_name,
		"offset": offset,
		"src_north": src_north,
		"facing": facing
	}
	get_tree().change_scene_to_file(target_scene_path)

func consume_pending_teleport_data():
	var data = pending_teleport_data
	pending_teleport_data = {}
	return data
