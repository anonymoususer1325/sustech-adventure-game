extends Control

@onready var npc_name_label = $NpcNameTextureRect/NpcNameContainer/NpcName          # NPC 名字 Label
@onready var text_label = $DialogPanel/DialogContentContainer/DialogContent   # 对话文本 Label
@onready var options_container = $OptionsContainer 

# 当前显示的对话数据（用于确认键）
var current_dialog_data: Dictionary = {}

func _ready():
	GameDialogManager.dialog_started.connect(_on_dialog_started)
	GameDialogManager.dialog_updated.connect(_on_dialog_updated)
	GameDialogManager.dialog_ended.connect(_on_dialog_ended)
	visible = false

func _on_dialog_started(dialog_data: Dictionary, npc: Node):
	current_dialog_data = dialog_data
	show()
	update_dialog(dialog_data, npc)

func _on_dialog_updated(dialog_data: Dictionary, npc: Node):
	current_dialog_data = dialog_data
	update_dialog(dialog_data, npc)

func _on_dialog_ended():
	hide()
	current_dialog_data = {}

func update_dialog(dialog_data: Dictionary, npc: Node):
	text_label.text = dialog_data.get("text", "")
	var npc_name = npc.get_display_name() if npc and npc.has_method("get_display_name") else "NPC"
	npc_name_label.text = npc_name
	
	# 清除旧选项按钮
	for child in options_container.get_children():
		child.queue_free()
	
	var options = dialog_data.get("options", [])
	if options.is_empty():
		# 没有选项，添加一个“继续”按钮，并让它获得焦点
		var continue_btn = Button.new()
		continue_btn.text = "继续"
		continue_btn.pressed.connect(_on_continue_pressed)
		options_container.add_child(continue_btn)
		continue_btn.grab_focus()
	else:
		# 有选项，创建按钮（用户可通过鼠标点击，暂不支持键盘选择）
		for i in range(options.size()):
			var btn = Button.new()
			btn.text = options[i].get("text", "选项")
			btn.pressed.connect(_on_option_selected.bind(i))
			options_container.add_child(btn)
		# 可让第一个按钮获得焦点（可选）
		if options_container.get_child_count() > 0:
			options_container.get_child(0).grab_focus()

func _on_continue_pressed():
	GameDialogManager.advance_dialog()

func _on_option_selected(option_index: int):
	GameDialogManager.select_option(option_index)

# 监听键盘确认键（空格/回车）
func _input(event):
	if not visible:	
		return
	if event.is_action_pressed("ui_accept"):
		GameDialogManager.advance_dialog()
		get_viewport().set_input_as_handled()
