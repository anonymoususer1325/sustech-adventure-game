# save_select_ui.gd
extends Control

const SLOT_COUNT = 4
var slots: Array = []

@onready var grid = $SavesGridContainer
@onready var new_game_button = $NewGameButtonContainer/NewGameButton

func _ready():
	for i in range(SLOT_COUNT):
		var slot = preload("res://scenes/ui/save_slot.tscn").instantiate()
		grid.add_child(slot)
		slots.append(slot)
		slot.set_slot_index(i)
		slot.set_selectable_on_empty(false)
		slot.slot_action.connect(_on_slot_action)
		update_slot_display(i)
	
	#await get_tree().process_frame
	call_deferred("_ensure_initial_focus")
	
	new_game_button.pressed.connect(_on_new_game_pressed)

# 根据删除的存档槽位重新设置焦点
func _refocus_after_deletion(deleted_slot: int):
	# 获取所有非空存档位的索引
	var non_empty = []
	for i in range(slots.size()):
		if not SaveManager.get_save_metadata(i).is_empty():
			non_empty.append(i)
	
	# 如果没有非空存档，焦点给新游戏按钮
	if non_empty.is_empty():
		new_game_button.grab_focus()
		return
	
	# 寻找比 deleted_slot 小的最大索引
	var smaller = non_empty.filter(func(idx): return idx < deleted_slot)
	if not smaller.is_empty():
		var target = smaller.max()
		slots[target].info_button.grab_focus()
		return
	
	# 否则寻找比 deleted_slot 大的最小索引
	var larger = non_empty.filter(func(idx): return idx > deleted_slot)
	if not larger.is_empty():
		var target = larger.min()
		slots[target].info_button.grab_focus()
		return
	
	# 保底（理论上不会到这里）
	new_game_button.grab_focus()

# 初始化焦点（无存档时聚焦新游戏按钮）
func _ensure_initial_focus():
	var has_non_empty = false
	for i in range(slots.size()):
		if not SaveManager.get_save_metadata(i).is_empty():
			has_non_empty = true
			break
	if not has_non_empty:
		new_game_button.grab_focus()
	else:
		# 可选：将焦点给第一个非空存档位
		for i in range(slots.size()):
			if not SaveManager.get_save_metadata(i).is_empty():
				slots[i].info_button.grab_focus()
				return

# 获取当前应获得焦点的控件（供外部调用，如暂停菜单）
func get_first_focusable() -> Control:
	# 优先找第一个非空存档位
	for i in range(slots.size()):
		if not SaveManager.get_save_metadata(i).is_empty():
			return slots[i].info_button
	# 如果没有非空存档，返回新游戏按钮
	return new_game_button

# 设置初始焦点
func _set_initial_focus():
	var target = get_first_focusable()
	if target:
		target.grab_focus()

func update_slot_display(slot: int):
	var metadata = SaveManager.get_save_metadata(slot)
	var is_empty = metadata.is_empty()
	slots[slot].set_empty(is_empty)
	if not is_empty:
		slots[slot].set_info(metadata)

func _on_slot_action(slot: int, action: String):
	match action:
		"info_pressed":
			# 用户点击了存档位（非空），进入操作模式（显示读取/删除/取消）
			slots[slot].enter_action_mode()
		"read":
			SaveManager.load_game(slot)
		"delete":
			# 用户确认删除后，执行删除操作并刷新显示
			var path = SaveManager.get_save_path(slot)
			DirAccess.remove_absolute(path)
			update_slot_display(slot)
			_refocus_after_deletion(slot)
		_:
			pass

func _on_new_game_pressed():
	# 开始新游戏的逻辑
	print("开始新游戏")
	# 重置游戏状态
	TaskManager.reset()
	InventoryManager.reset()
	# 切换到初始场景
	get_tree().change_scene_to_file("res://scenes/levels/campus_LH3_mid.tscn")
