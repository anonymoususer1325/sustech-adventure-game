extends CanvasLayer

signal resume_pressed
#signal save_pressed
signal main_menu_pressed

@onready var btn_resume = $PauseMenuPanel/OptionContainer/btn_resume
@onready var btn_save = $PauseMenuPanel/OptionContainer/btn_save
@onready var btn_main_menu = $PauseMenuPanel/OptionContainer/btn_main_menu
@onready var right_panel = $RightPanel

var current_sub_ui: Control = null   # 当前显示的子界面

func _ready():
	btn_resume.pressed.connect(_on_resume)
	btn_save.pressed.connect(_on_save)
	btn_main_menu.pressed.connect(_on_main_menu)
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible:
		reset_focus()

func reset_focus():
	# 如果没有子界面，焦点给“继续”按钮
	if not current_sub_ui:
		btn_resume.grab_focus()
	else:
		# 如果有子界面，将焦点交给子界面的第一个可聚焦控件
		pass  # 子界面自身会处理焦点

func open_sub_ui(sub_ui_scene: PackedScene):
	# 关闭已有子界面
	if current_sub_ui:
		current_sub_ui.queue_free()
	# 实例化新子界面
	current_sub_ui = sub_ui_scene.instantiate()
	right_panel.add_child(current_sub_ui)
	# 调整子界面大小适应右侧面板（子界面应设置 anchors 为全填充）
	current_sub_ui.anchor_right = 1
	current_sub_ui.anchor_bottom = 1
	# 等待一帧，让子界面完成初始化，然后转移焦点
	await get_tree().process_frame
	
	# 连接子界面的关闭请求信号（必须在实例化后）
	if current_sub_ui.has_signal("close_requested"):
		current_sub_ui.close_requested.connect(_on_sub_ui_close_requested)
	
	# 子界面需要提供 get_first_focusable 方法
	if current_sub_ui.has_method("get_first_focusable"):
		var first = current_sub_ui.get_first_focusable()
		if first:
			first.grab_focus()

func close_sub_ui():
	if current_sub_ui:
		current_sub_ui.queue_free()
		current_sub_ui = null
	# 返回主界面焦点
	btn_save.grab_focus()   # 因为是从保存按钮进入的，返回后聚焦保存按钮

func _input(event):
	if not visible:
		return
	# ESC 键处理：如果有子界面，关闭子界面；否则关闭整个暂停菜单（相当于按继续）
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if current_sub_ui:
			close_sub_ui()
		else:
			resume_pressed.emit()

func _on_resume():
	resume_pressed.emit()

func _on_save():
	# 打开保存界面
	var save_ui_scene = preload("res://scenes/ui/save_ui.tscn")
	open_sub_ui(save_ui_scene)

func _on_main_menu():
	main_menu_pressed.emit()

func _on_sub_ui_close_requested():
	close_sub_ui()
