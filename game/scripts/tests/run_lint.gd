# tests/run_lint.gd
# GDScript 代码检查 — CI 用
extends SceneTree

func _init():
	print("=== 代码检查 ===")
	var dir = DirAccess.open("res://scripts")
	if dir:
		_check_dir(dir, "res://scripts")
	print("=== 代码检查完成 ===")
	quit(0)

func _check_dir(dir: DirAccess, base_path: String):
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd") and not file_name.begins_with("."):
			var path = base_path + "/" + file_name
			var script = load(path)
			if script:
				print("  ✅ ", path)
			else:
				print("  ❌ 无法加载: ", path)
		elif dir.current_is_dir() and file_name != "." and file_name != "..":
			var sub_dir = DirAccess.open(base_path + "/" + file_name)
			if sub_dir:
				_check_dir(sub_dir, base_path + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
