# tests/run_tests.gd
# GDScript 测试运行器 — CI 用
extends SceneTree

func _init():
	print("=== 运行测试 ===")
	
	# 测试 JSON 数据文件可解析
	test_json_files()
	
	# 测试 Autoload 单例存在
	test_autoloads()
	
	print("=== 测试完成 ===")
	quit(0)

func test_json_files():
	var files = [
		"res://data/items.json",
		"res://data/tasks.json",
		"res://data/dialogs.json"
	]
	for path in files:
		var f = FileAccess.open(path, FileAccess.READ)
		assert(f != null, "无法打开文件: " + path)
		var content = f.get_as_text()
		f.close()
		var json = JSON.new()
		assert(json.parse(content) == OK, "JSON 解析失败: " + path)
		print("  ✅ 数据文件正常: ", path)

func test_autoloads():
	var names = [
		"SaveManager", "InventoryManager", "TaskManager",
		"SceneManager", "GameState", "LightEffectManager",
		"InteractionManager", "GameDialogManager", "GameClock"
	]
	for name in names:
		var node = get_root().get_node_or_null(name)
		assert(node != null, "Autoload 未找到: " + name)
		print("  ✅ Autoload 正常: ", name)
