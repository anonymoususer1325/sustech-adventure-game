# tests/run_tests.gd
# GDScript 测试运行器 — CI 用
extends SceneTree

var _failed: bool = false

func _init():
	print("=== 运行测试 ===")
	test_json_files()
	test_autoloads()
	test_scene_files()
	if _failed:
		print("  ❌ 测试失败！")
		quit(1)
	else:
		print("  ✅ 所有测试通过")
		quit(0)

func fail(msg: String):
	print("  ❌ ", msg)
	_failed = true

func test_json_files():
	var files = [
		"res://data/items.json",
		"res://data/tasks.json",
		"res://data/dialogs.json"
	]
	for path in files:
		var f = FileAccess.open(path, FileAccess.READ)
		if f == null:
			fail("无法打开文件: " + path)
			continue
		var content = f.get_as_text()
		f.close()
		var json = JSON.new()
		var err = json.parse(content)
		if err != OK:
			fail("JSON 解析失败: " + path + " — " + json.get_error_message())
		else:
			print("  ✅ 数据文件正常: ", path)

func test_autoloads():
	var names = [
		"SaveManager", "InventoryManager", "TaskManager",
		"SceneManager", "GameState", "LightEffectManager",
		"InteractionManager", "GameDialogManager", "GameClock"
	]
	for name in names:
		var node = get_root().get_node_or_null(name)
		if node == null:
			fail("Autoload 未找到: " + name)
		else:
			print("  ✅ Autoload 正常: ", name)

func test_scene_files():
	# 验证关键场景文件存在
	var scenes = [
		"res://scenes/levels/campus_LH3_sou.tscn",
		"res://scenes/levels/campus_LH3_mid.tscn",
		"res://scenes/levels/campus_library.tscn",
		"res://scenes/levels/campus_dormitory.tscn",
		"res://scenes/levels/campus_teaching.tscn",
		"res://scenes/ui/main_menu.tscn",
		"res://scenes/characters/player.tscn",
	]
	for path in scenes:
		if ResourceLoader.exists(path):
			print("  ✅ 场景存在: ", path)
		else:
			fail("场景不存在: " + path)

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
