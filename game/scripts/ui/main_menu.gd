extends Control

var menu_items: Array[Button]
var current_index: int = 0
var highlight_style: StyleBoxFlat

func _ready():
	# 收集按钮
	menu_items = [
		$VBoxContainer/btn_explore,
		$VBoxContainer/btn_multi,
		$VBoxContainer/btn_settings,
		$VBoxContainer/btn_quit
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

func _input(event):
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
	print("进入独自探索模式")
	# TODO: 切换场景

func _on_multi():
	print("进入多人切磋模式")
	# TODO: 打开多人界面

func _on_settings():
	print("打开设置界面")
	# TODO: 打开设置界面

func _on_quit():
	get_tree().quit()
