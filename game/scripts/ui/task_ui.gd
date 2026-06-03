# task_ui.gd
# 任务管理器 UI
# 显示任务列表、详情、焦点任务设置、过滤和排序

extends Control

# ======================== 节点引用 ========================
@onready var task_list_container: VBoxContainer = $CenterContainer/Background/ListPanel/ScrollContainer/TaskListContainer
@onready var task_list_scroll: ScrollContainer = $CenterContainer/Background/ListPanel/ScrollContainer
@onready var detail_name: Label = $CenterContainer/Background/DetailPanel/TaskName
@onready var detail_desc: Label = $CenterContainer/Background/DetailPanel/TaskDescription
@onready var detail_status: Label = $CenterContainer/Background/DetailPanel/TaskStatus
@onready var detail_progress: Label = $CenterContainer/Background/DetailPanel/TaskProgress
@onready var focus_hint: Label = $CenterContainer/Background/DetailPanel/FocusHint
@onready var set_focus_btn: Button = $CenterContainer/Background/DetailPanel/SetFocusButton
@onready var filter_btn_all: Button = $CenterContainer/Background/FilterContainer/FilterAll
@onready var filter_btn_inprogress: Button = $CenterContainer/Background/FilterContainer/FilterInProgress
@onready var filter_btn_completed: Button = $CenterContainer/Background/FilterContainer/FilterCompleted
@onready var sort_btn_time: Button = $CenterContainer/Background/SortContainer/SortByTime
@onready var sort_btn_progress: Button = $CenterContainer/Background/SortContainer/SortByProgress
@onready var auto_focus_check: CheckBox = $CenterContainer/Background/DetailPanel/AutoFocusCheck
@onready var close_btn: Button = $CenterContainer/Background/CloseButton
@onready var empty_hint: Label = $CenterContainer/Background/EmptyHint

# ======================== 状态 ========================
var _task_buttons: Array = []       # [Button]
var _selected_task_id: String = ""

# ======================== 生命周期 ========================
func _ready():
	TaskManager.tasks_updated.connect(_refresh)
	TaskManager.focus_task_changed.connect(_on_focus_changed)
	
	close_btn.pressed.connect(_close)
	set_focus_btn.pressed.connect(_on_set_focus_pressed)
	auto_focus_check.toggled.connect(_on_auto_focus_toggled)
	
	filter_btn_all.pressed.connect(func(): TaskManager.set_filter_mode(TaskManager.FilterMode.ALL))
	filter_btn_inprogress.pressed.connect(func(): TaskManager.set_filter_mode(TaskManager.FilterMode.IN_PROGRESS))
	filter_btn_completed.pressed.connect(func(): TaskManager.set_filter_mode(TaskManager.FilterMode.COMPLETED))
	sort_btn_time.pressed.connect(func(): TaskManager.set_sort_mode(TaskManager.SortMode.TRIGGER_TIME))
	sort_btn_progress.pressed.connect(func(): TaskManager.set_sort_mode(TaskManager.SortMode.PROGRESS))
	
	visible = false
	_refresh()

# ======================== 打开/关闭 ========================
func open():
	_refresh()
	visible = true
	get_tree().paused = true
	_focus_first_task()

func close():
	visible = false
	get_tree().paused = false

func _close():
	close()

func toggle():
	if visible:
		close()
	else:
		open()

# ======================== 刷新 ========================
func _refresh():
	_update_filter_sort_buttons()
	_rebuild_task_list()
	_update_detail_panel()
	_update_empty_hint()
	_update_auto_focus_check()

func _update_filter_sort_buttons():
	# 更新过滤按钮样式
	filter_btn_all.disabled = (TaskManager.filter_mode == TaskManager.FilterMode.ALL)
	filter_btn_inprogress.disabled = (TaskManager.filter_mode == TaskManager.FilterMode.IN_PROGRESS)
	filter_btn_completed.disabled = (TaskManager.filter_mode == TaskManager.FilterMode.COMPLETED)
	
	sort_btn_time.disabled = (TaskManager.sort_mode == TaskManager.SortMode.TRIGGER_TIME)
	sort_btn_progress.disabled = (TaskManager.sort_mode == TaskManager.SortMode.PROGRESS)

func _update_empty_hint():
	var task_ids = TaskManager.get_filtered_tasks()
	empty_hint.visible = task_ids.is_empty()

func _update_auto_focus_check():
	auto_focus_check.button_pressed = TaskManager.auto_select_focus

# ======================== 构建任务列表 ========================
func _rebuild_task_list():
	for btn in _task_buttons:
		btn.queue_free()
	_task_buttons.clear()
	
	var task_ids = TaskManager.get_filtered_tasks()
	
	for tid in task_ids:
		var btn = _create_task_button(tid)
		task_list_container.add_child(btn)
		_task_buttons.append(btn)

func _create_task_button(task_id: String) -> Button:
	var btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = _get_task_button_text(task_id)
	btn.pressed.connect(_on_task_button_pressed.bind(task_id))
	btn.focus_entered.connect(_on_task_focus_entered.bind(task_id))
	
	# 焦点任务高亮
	if task_id == TaskManager.get_focus_task_id():
		btn.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	
	return btn

func _get_task_button_text(task_id: String) -> String:
	var def = TaskManager.get_task_data(task_id)
	if not def:
		return task_id
	
	var status_text = TaskManager.get_status_text(task_id)
	var progress_text = TaskManager.get_progress_text(task_id)
	var focus_mark = " ★" if task_id == TaskManager.get_focus_task_id() else ""
	
	return def.name + "  [" + status_text + "] " + progress_text + focus_mark

# ======================== 选中逻辑 ========================
func _on_task_button_pressed(task_id: String):
	if _selected_task_id == task_id:
		# 已经选中：尝试切换焦点
		TaskManager.toggle_focus_task(task_id)
	_refresh()

func _on_task_focus_entered(task_id: String):
	_selected_task_id = task_id
	_update_detail_panel()
	_update_set_focus_button()

func _focus_first_task():
	if _task_buttons.size() > 0:
		_task_buttons[0].grab_focus()

# ======================== 详情面板 ========================
func _update_detail_panel():
	if _selected_task_id.is_empty() or not TaskManager.get_task_data(_selected_task_id):
		detail_name.text = ""
		detail_desc.text = ""
		detail_status.text = ""
		detail_progress.text = ""
		focus_hint.visible = false
		return
	
	var def = TaskManager.get_task_data(_selected_task_id)
	detail_name.text = def.name
	detail_desc.text = def.description
	detail_status.text = "状态: " + TaskManager.get_status_text(_selected_task_id)
	detail_progress.text = "进度: " + TaskManager.get_progress_text(_selected_task_id)
	
	# 焦点提示
	var focus_id = TaskManager.get_focus_task_id()
	if focus_id == _selected_task_id:
		focus_hint.text = "当前为焦点任务 ✓"
		focus_hint.visible = true
	elif focus_id.is_empty():
		focus_hint.text = "未设置焦点任务。选择一个进行中的任务设为焦点以追踪进度。"
		focus_hint.visible = true
	else:
		var focus_def = TaskManager.get_focus_task_data()
		focus_hint.text = "当前焦点: " + (focus_def.name if focus_def else "") 
		focus_hint.visible = true

func _update_set_focus_button():
	var status = TaskManager.get_task_status(_selected_task_id)
	var is_focus = _selected_task_id == TaskManager.get_focus_task_id()
	
	if status == TaskManager.TaskStatus.IN_PROGRESS:
		set_focus_btn.disabled = false
		set_focus_btn.text = "取消焦点" if is_focus else "设为焦点任务"
	else:
		set_focus_btn.disabled = true
		set_focus_btn.text = "仅进行中任务可设为焦点"

func _on_set_focus_pressed():
	if not _selected_task_id.is_empty():
		TaskManager.toggle_focus_task(_selected_task_id)
		_refresh()

func _on_focus_changed(_task_id: String):
	_refresh()

func _on_auto_focus_toggled(button_pressed: bool):
	TaskManager.auto_select_focus = button_pressed

# ======================== 输入处理 ========================
func _input(event):
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

# ======================== 获取焦点控件（供暂停菜单使用） ========================
func get_first_focusable() -> Control:
	if _task_buttons.size() > 0:
		return _task_buttons[0]
	return close_btn
