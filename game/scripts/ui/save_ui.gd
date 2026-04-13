# SaveUI.gd
extends Control

const SLOT_COUNT = 4
var slots: Array = []

@onready var cancel_button = $CancelButtonContainer/CancelButton
@onready var grid = $SavesGridContainer

# SaveUI.gd 增加信号
signal close_requested


func _ready():
	for i in range(SLOT_COUNT):
		var slot = preload("res://scenes/ui/save_slot.tscn").instantiate()
		grid.add_child(slot)
		slots.append(slot)
		slot.set_slot_index(i)
		slot.set_selectable_on_empty(true)
		slot.slot_action.connect(_on_slot_action)
		slot.save_requested.connect(_on_save_requested)
		update_slot_display(i)
	
	#await get_tree().process_frame
	call_deferred("_set_initial_focus")
	
	cancel_button.pressed.connect(_on_cancel_pressed)

func _on_cancel_pressed():
	close_requested.emit()

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
			var metadata = SaveManager.get_save_metadata(slot)
			if metadata.is_empty():
				# 空存档：直接保存
				SaveManager.save_game(slot)
				update_slot_display(slot)
			else:
				# 非空存档：进入覆盖选择模式
				slots[slot].enter_overwrite_mode()
		"overwrite":
			# 用户在覆盖选择模式下选择了“覆盖”
			if slot == SaveManager.current_slot:
				# 同一存档，直接保存
				SaveManager.save_game(slot)
				update_slot_display(slot)
				slots[slot].exit_overwrite_mode()   # 新增：退出覆盖模式
			else:
				# 不同存档，进入二次确认模式
				slots[slot].enter_confirm_overwrite_mode()
		_:
			pass

func _on_save_requested(slot: int):
	# 二次确认后最终保存
	SaveManager.save_game(slot)
	update_slot_display(slot)

# 在需要关闭的地方（如保存完成后、用户点击返回按钮等）发射信号
func _on_save_completed():
	close_requested.emit()

# 获取当前应获得焦点的控件（供外部调用，例如 pause_menu）
func get_first_focusable() -> Control:
	if SaveManager.current_slot >= 0:
		var target_slot = SaveManager.current_slot
		# 如果 current_slot 有效且对应存档位存在
		if target_slot >= 0 and target_slot < slots.size():
			return slots[target_slot].info_button
		else:
			# 否则回退到第一个非空存档位，若无则第一个存档位
			for i in range(slots.size()):
				if not SaveManager.get_save_metadata(i).is_empty():
					return slots[i].info_button
			if slots.size() > 0:
				return slots[0].info_button
	else:
		# 优先寻找第一个空存档位
		for i in range(slots.size()):
			if SaveManager.get_save_metadata(i).is_empty():
				return slots[i].info_button
		# 如果没有空存档位（即全部非空），则返回第一个存档位（左上角）
		if slots.size() > 0:
			return slots[0].info_button
	return null
