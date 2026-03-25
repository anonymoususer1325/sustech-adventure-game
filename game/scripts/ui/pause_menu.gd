extends CanvasLayer

signal resume_pressed
signal save_pressed
signal main_menu_pressed

@onready var btn_resume = $PauseMenuPanel/OptionContainer/btn_resume
@onready var btn_save = $PauseMenuPanel/OptionContainer/btn_save
@onready var btn_main_menu = $PauseMenuPanel/OptionContainer/btn_main_menu

var menu_items: Array[Button]
var current_index: int = 0
var highlight_style: StyleBoxFlat

func _ready():
	menu_items = [btn_resume, btn_save, btn_main_menu]
	
	highlight_style = StyleBoxFlat.new()
	highlight_style.bg_color = Color(0x3399ff)
	highlight_style.set_corner_radius_all(5)
	
	var default_style = btn_resume.get_theme_stylebox("normal")
	if default_style:
		highlight_style.content_margin_top = default_style.content_margin_top
		highlight_style.content_margin_right = default_style.content_margin_right
		highlight_style.content_margin_bottom = default_style.content_margin_bottom
		highlight_style.content_margin_left = default_style.content_margin_left
	
	btn_resume.pressed.connect(_on_resume)
	btn_save.pressed.connect(_on_save)
	btn_main_menu.pressed.connect(_on_main_menu)
	
	current_index = 0
	update_highlight()

func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_up"):
		current_index = (current_index - 1 + menu_items.size()) % menu_items.size()
		update_highlight()
		get_viewport().set_input_as_handled()   # ← 修正
	elif event.is_action_pressed("ui_down"):
		current_index = (current_index + 1) % menu_items.size()
		update_highlight()
		get_viewport().set_input_as_handled()   # ← 修正
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()   # ← 修正
		resume_pressed.emit()
		current_index = 0
		update_highlight()
	elif event.is_action_pressed("ui_accept"):
		# 先标记输入已处理
		get_viewport().set_input_as_handled()   # ← 修正
		# 再执行操作
		match current_index:
			0:
				resume_pressed.emit()
			1:
				save_pressed.emit()
			2:
				main_menu_pressed.emit()
		current_index = 0
		update_highlight()

func update_highlight():
	for btn in menu_items:
		btn.remove_theme_stylebox_override("normal")
	var current_btn = menu_items[current_index]
	current_btn.add_theme_stylebox_override("normal", highlight_style)

func reset_focus():
	current_index = 0
	update_highlight()

func _on_resume():
	resume_pressed.emit()

func _on_save():
	save_pressed.emit()

func _on_main_menu():
	main_menu_pressed.emit()
