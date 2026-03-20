extends Control

var menu_items: Array[Button]
var current_index: int = 0
var highlight_style: StyleBoxFlat

# 子界面节点引用
@onready var explore_panel = $ExplorePanel
@onready var multi_panel = $MultiPanel
@onready var settings_panel = $SettingsPanel
@onready var menu_container = $OptionContainer   # 你的主菜单按钮容器，根据实际路径调整

# 当前激活的子界面（null 表示主菜单）
var active_subpanel: Control = null

func _ready():
	# 收集按钮
	menu_items = [
		$OptionContainer/btn_explore,
		$OptionContainer/btn_multi,
		$OptionContainer/btn_settings,
		$OptionContainer/btn_quit
	]
	
	# 创建高亮样式（黄色背景，圆角）
	highlight_style = StyleBoxFlat.new()
	highlight_style.bg_color = Color(0x66c9fab8)
	highlight_style.set_corner_radius_all(5)
	
	# 复制默认样式的内容边距
	var default_style = menu_items[0].get_theme_stylebox("normal")
	if default_style:
		highlight_style.content_margin_top = default_style.content_margin_top
		highlight_style.content_margin_right = default_style.content_margin_right
		highlight_style.content_margin_bottom = default_style.content_margin_bottom
		highlight_style.content_margin_left = default_style.content_margin_left
	
	# 连接按钮信号
	menu_items[0].pressed.connect(_on_explore)
	menu_items[1].pressed.connect(_on_multi)
	menu_items[2].pressed.connect(_on_settings)
	menu_items[3].pressed.connect(_on_quit)
	
	update_highlight()
	
	# 确保子界面初始不可见
	explore_panel.visible = false
	multi_panel.visible = false
	settings_panel.visible = false

func _input(event):
	# 处理返回键：当子界面打开时，返回主菜单
	if event.is_action_pressed("ui_cancel"):
		if active_subpanel != null:
			# 有子界面打开，关闭它
			close_active_subpanel()
		else:
			# 在主菜单界面，按返回键退出游戏
			get_tree().quit()
		accept_event()
		return  # 重要：阻止后续代码再次处理同一事件
			
	if active_subpanel == null:
		if event.is_action_pressed("ui_up"):
			current_index = (current_index - 1 + menu_items.size()) % menu_items.size()
			update_highlight()
			accept_event()
		elif event.is_action_pressed("ui_down"):
			current_index = (current_index + 1) % menu_items.size()
			update_highlight()
			accept_event()
		elif event.is_action_pressed("ui_accept"):
			menu_items[current_index].pressed.emit()
			accept_event()
		elif event.is_action_pressed("ui_cancel"):
			get_tree().quit()

func update_highlight():
	# 清除所有按钮的高亮样式
	for btn in menu_items:
		btn.remove_theme_stylebox_override("normal")
	
	# 为当前选中的按钮设置高亮背景
	var current_btn = menu_items[current_index]
	current_btn.add_theme_stylebox_override("normal", highlight_style)

func _on_explore():
	open_subpanel(explore_panel)

func _on_multi():
	open_subpanel(multi_panel)

func _on_settings():
	open_subpanel(settings_panel)

func _on_quit():
	get_tree().quit()

# 打开指定子界面
func open_subpanel(panel: Control):
	# 隐藏主菜单按钮容器
	menu_container.visible = false
	# 隐藏其他子界面（确保只有一个显示）
	explore_panel.visible = false
	multi_panel.visible = false
	settings_panel.visible = false
	# 显示目标子界面
	panel.visible = true
	active_subpanel = panel

# 关闭当前子界面，返回主菜单
func close_active_subpanel():
	if active_subpanel:
		active_subpanel.visible = false
		active_subpanel = null
	# 显示主菜单按钮容器
	menu_container.visible = true
	# 恢复高亮（可选：重新聚焦第一个选项）
	current_index = 0
	update_highlight()
