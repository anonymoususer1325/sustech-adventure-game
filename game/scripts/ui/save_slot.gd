extends Control

# 信号
signal slot_action(slot_index: int, action: String)   # 用于读档：read, delete
signal save_requested(slot_index: int)                # 用于存档：直接保存

# 导出变量
@export var slot_index: int = 0

var selectable_on_empty: bool = false

# 节点引用
@onready var info_button = $InfoButton
@onready var interface = $Interface
@onready var info_label = $Interface/InfoContainer/Info
@onready var button_container = $Interface/ButtonContainer

# 模式枚举
enum Mode { INFO, ACTION, CONFIRM_DELETE, OVERWRITE, CONFIRM_OVERWRITE }
var current_mode: Mode = Mode.INFO

func _ready():
	info_button.pressed.connect(_on_info_pressed)
	switch_mode(Mode.INFO)

# 设置存档索引
func set_slot_index(idx: int):
	slot_index = idx

func set_selectable_on_empty(selectable: bool):
	selectable_on_empty = selectable

# 设置存档为空（显示空提示）
func set_empty(empty: bool):
	info_button.disabled = empty
	if empty:
		info_button.text = "这里空空如也……"
		info_button.disabled = not selectable_on_empty
		info_button.focus_mode = Control.FOCUS_ALL if selectable_on_empty else Control.FOCUS_NONE

# 设置存档信息（非空时调用）
func set_info(metadata: Dictionary):
	var info = ""
	info += "主线: " + metadata.get("main_quest_progress", "") + "\n"
	info += "支线: " + str(metadata.get("side_quests_completed", 0)) + "\n"
	info += "焦点: " + metadata.get("current_focus_task", "") + "\n"
	
	# 获取浮点数游玩时间（秒）
	var play_time_float = metadata.get("play_time_seconds", 0.0)
	var total_seconds = int(play_time_float)   # 向下取整为整数秒
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60
	var time_str = "%02d:%02d:%02d" % [hours, minutes, seconds]
	info += "时长: " + time_str + "\n"
	
	info += "保存: " + metadata.get("save_time", "")
	info_button.text = info

# 外部调用：进入操作模式（读档用）
func enter_action_mode():
	switch_mode(Mode.ACTION)

# 外部调用：进入覆盖选择模式（存档用，第一次确认）
func enter_overwrite_mode():
	switch_mode(Mode.OVERWRITE)

# 外部调用：进入二次覆盖确认（存档用，第二次确认）
func enter_confirm_overwrite_mode():
	switch_mode(Mode.CONFIRM_OVERWRITE)

# 核心：切换模式
func switch_mode(mode: Mode):
	current_mode = mode
	info_button.visible = (mode == Mode.INFO)
	interface.visible = (mode != Mode.INFO)
	
	# 清空旧按钮
	var old_buttons = button_container.get_children()
	for btn in old_buttons:
		button_container.remove_child(btn)
		btn.queue_free()
	
	# 根据模式配置界面
	match mode:
		Mode.INFO:
			# 让 info_button 获取焦点
			info_button.grab_focus()
		Mode.ACTION:
			info_label.text = "请选择需要对此存档进行的操作。"
			info_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			var read_btn = create_button("读取")
			var delete_btn = create_button("删除")
			var cancel_btn = create_button("取消")
			button_container.add_child(read_btn)
			button_container.add_child(delete_btn)
			button_container.add_child(cancel_btn)
			read_btn.pressed.connect(_on_read_pressed)
			delete_btn.pressed.connect(_on_delete_pressed)
			cancel_btn.pressed.connect(_on_cancel_pressed)
			# 默认焦点在读取
			read_btn.grab_focus()
		Mode.CONFIRM_DELETE:
			info_label.text = "删除的存档将永远无法恢复！\n真的要删除吗？"
			info_label.add_theme_color_override("font_color", Color(1.0, 0.498, 0.498))
			var confirm_btn = create_button("确认删除")
			var cancel_btn = create_button("取消")
			button_container.add_child(confirm_btn)
			button_container.add_child(cancel_btn)
			confirm_btn.pressed.connect(_on_confirm_delete_pressed)
			cancel_btn.pressed.connect(_on_cancel_pressed)
			cancel_btn.grab_focus()  # 默认焦点在取消
		Mode.OVERWRITE:
			info_label.text = "是否覆盖此存档？"
			info_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			var overwrite_btn = create_button("覆盖")
			var cancel_btn = create_button("取消")
			button_container.add_child(overwrite_btn)
			button_container.add_child(cancel_btn)
			overwrite_btn.pressed.connect(_on_overwrite_pressed)
			cancel_btn.pressed.connect(_on_cancel_pressed)
			overwrite_btn.grab_focus()  # 默认焦点在覆盖
		Mode.CONFIRM_OVERWRITE:
			info_label.text = "警告：这不是同一存档的早期版本。\n被覆盖的数据将永远无法找回！"
			info_label.add_theme_color_override("font_color", Color(1.0, 0.498, 0.498))
			var confirm_btn = create_button("确认覆盖")
			var cancel_btn = create_button("取消")
			button_container.add_child(confirm_btn)
			button_container.add_child(cancel_btn)
			confirm_btn.pressed.connect(_on_confirm_overwrite_pressed)
			cancel_btn.pressed.connect(_on_cancel_pressed)
			cancel_btn.grab_focus()  # 默认焦点在取消
	
	var buttons = button_container.get_children()
	_setup_focus_neighbors(buttons)

# 辅助：创建按钮并设置样式
func create_button(text: String) -> Button:
	var btn = Button.new()
	btn.button_mask = false
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if text == "确认覆盖" or text == "删除" or text == "确认删除":
		btn.add_theme_color_override("font_color", Color(0.875, 0.435, 0.435))
		btn.add_theme_color_override("font_focus_color", Color(0.949, 0.475, 0.475))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.498, 0.498))
	return btn

func _setup_focus_neighbors(buttons: Array):
	if buttons.is_empty():
		return
	#print("size: ", buttons.size())
	var first = buttons[0]
	#print("first: ", first)
	var last = buttons[-1]
	#print("last: ", last)
	for btn in buttons:
		btn.focus_neighbor_top = btn.get_path()
		btn.focus_neighbor_bottom = btn.get_path()
		btn.focus_next = btn.get_path()
		btn.focus_previous = btn.get_path()
	first.focus_neighbor_left = first.get_path()
	last.focus_neighbor_right = last.get_path()

# 按钮事件处理
func _on_info_pressed():
	if info_button.disabled:
		return
	# 根据使用场景，外部决定进入哪种模式（通过调用 enter_action_mode 或 enter_overwrite_mode）
	# 这里我们发射一个信号，由外部决定下一步
	slot_action.emit(slot_index, "info_pressed")

func _on_read_pressed():
	slot_action.emit(slot_index, "read")
	# 删除 switch_mode(Mode.INFO) 这一行

func _on_delete_pressed():
	switch_mode(Mode.CONFIRM_DELETE)

func _on_confirm_delete_pressed():
	slot_action.emit(slot_index, "delete")
	switch_mode(Mode.INFO)

func _on_overwrite_pressed():
	# 第一次覆盖确认：由外部判断是否同一存档，决定是否进入二次确认
	slot_action.emit(slot_index, "overwrite")

func exit_overwrite_mode():
	if current_mode == Mode.OVERWRITE:
		switch_mode(Mode.INFO)

func _on_confirm_overwrite_pressed():
	save_requested.emit(slot_index)
	switch_mode(Mode.INFO)

func _on_cancel_pressed():
	match current_mode:
		Mode.CONFIRM_DELETE:
			switch_mode(Mode.ACTION)
		Mode.CONFIRM_OVERWRITE:
			switch_mode(Mode.OVERWRITE)
		_:
			switch_mode(Mode.INFO)

# ESC 键处理
func _input(event):
	if interface.visible and event.is_action_pressed("ui_cancel"):
		match current_mode:
			Mode.CONFIRM_DELETE, Mode.CONFIRM_OVERWRITE:
				# 返回到上一级模式（ACTION 或 OVERWRITE）
				if current_mode == Mode.CONFIRM_DELETE:
					switch_mode(Mode.ACTION)
				else:
					switch_mode(Mode.OVERWRITE)
				accept_event()
			Mode.ACTION, Mode.OVERWRITE:
				# 返回到 INFO 模式
				switch_mode(Mode.INFO)
				accept_event()
			Mode.INFO:
				# 不处理，让事件传递给父级（即 pause_menu）
				pass
