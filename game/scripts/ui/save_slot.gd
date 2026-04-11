extends Control

signal slot_action(slot_index: int, action: String)   # action: "read", "delete"

@export var slot_index: int = 0

@onready var info_button = $InfoButton
@onready var action_panel = $Action
@onready var confirm_panel = $Confirm
@onready var read_btn = $Action/ButtonContainer/Read
@onready var delete_btn = $Action/ButtonContainer/Delete
@onready var cancel_action_btn = $Action/ButtonContainer/Cancel
@onready var confirm_delete_btn = $Confirm/ButtonContainer/ConfirmDelete
@onready var cancel_confirm_btn = $Confirm/ButtonContainer/Cancel

enum Mode { INFO, ACTION, CONFIRM }
var current_mode: Mode = Mode.INFO

func _ready():
	# 连接按钮信号
	info_button.pressed.connect(_on_info_pressed)
	read_btn.pressed.connect(_on_read_pressed)
	delete_btn.pressed.connect(_on_delete_pressed)
	cancel_action_btn.pressed.connect(_on_cancel_action_pressed)
	confirm_delete_btn.pressed.connect(_on_confirm_delete_pressed)
	cancel_confirm_btn.pressed.connect(_on_cancel_confirm_pressed)
	
	# 设置焦点邻居（左右键在按钮间移动）
	read_btn.focus_neighbor_right = delete_btn.get_path()
	delete_btn.focus_neighbor_left = read_btn.get_path()
	delete_btn.focus_neighbor_right = cancel_action_btn.get_path()
	cancel_action_btn.focus_neighbor_left = delete_btn.get_path()
	
	confirm_delete_btn.focus_neighbor_right = cancel_confirm_btn.get_path()
	cancel_confirm_btn.focus_neighbor_left = confirm_delete_btn.get_path()
	
	# 初始显示信息模式
	switch_mode(Mode.INFO)

func get_info_button() -> Button:
	return info_button

func set_slot_index(idx: int):
	slot_index = idx

func set_empty(empty: bool):
	info_button.disabled = empty
	if empty:
		info_button.text = "这里空空如也……"
	else:
		info_button.text = "加载中..."  # 临时

func set_info(metadata: Dictionary):
	var info = ""
	info += "主线: " + metadata.get("main_quest_progress", "") + "\n"
	info += "支线: " + str(metadata.get("side_quests_completed", 0)) + "\n"
	info += "焦点: " + metadata.get("current_focus_task", "") + "\n"
	var play_time = metadata.get("play_time_seconds", 0)
	var total_seconds = int(play_time)
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60
	var time_str = "%02d:%02d:%02d" % [hours, minutes, seconds]
	info += "时长: " + time_str + "\n"
	info += "保存: " + metadata.get("save_time", "")
	info_button.text = info

func switch_mode(mode: Mode):
	current_mode = mode
	info_button.visible = (mode == Mode.INFO)
	action_panel.visible = (mode == Mode.ACTION)
	confirm_panel.visible = (mode == Mode.CONFIRM)
	
	# 根据模式设置默认焦点
	match mode:
		Mode.INFO:
			info_button.grab_focus()
		Mode.ACTION:
			read_btn.grab_focus()
		Mode.CONFIRM:
			# 默认焦点放在右侧的“取消”按钮，避免误删除
			cancel_confirm_btn.grab_focus()

func _on_info_pressed():
	if info_button.disabled:
		return
	switch_mode(Mode.ACTION)

func _on_read_pressed():
	slot_action.emit(slot_index, "read")
	# 读取后，存档选择界面会加载游戏，当前场景销毁，不需要返回

func _on_delete_pressed():
	switch_mode(Mode.CONFIRM)

func _on_cancel_action_pressed():
	switch_mode(Mode.INFO)

func _on_confirm_delete_pressed():
	slot_action.emit(slot_index, "delete")
	# 删除后，外部会刷新显示，切换回信息模式
	switch_mode(Mode.INFO)   # 先切换到信息模式，等待外部刷新

func _on_cancel_confirm_pressed():
	switch_mode(Mode.ACTION)

func _input(event):
	# ESC 键返回上一级
	if event.is_action_pressed("ui_cancel"):
		match current_mode:
			Mode.ACTION:
				switch_mode(Mode.INFO)
				accept_event()
			Mode.CONFIRM:
				switch_mode(Mode.ACTION)
				accept_event()
			_:
				pass
