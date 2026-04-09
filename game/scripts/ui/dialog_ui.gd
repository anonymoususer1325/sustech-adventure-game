extends CanvasLayer

@onready var text_label = $DialogPanel/DialogContentContainer/DialogContent
@onready var options_container = $OptionsContainer
@onready var npc_name_label = $NpcNameTextureRect/NpcNameContainer/NpcName

func _ready():
	GameDialogManager.dialog_started.connect(_on_dialog_started)
	GameDialogManager.dialog_updated.connect(_on_dialog_updated)
	GameDialogManager.dialog_ended.connect(_on_dialog_ended)
	hide()

func _on_dialog_started(dialog_data: Dictionary):
	show()
	update_dialog(dialog_data)

func _on_dialog_updated(dialog_data: Dictionary):
	update_dialog(dialog_data)

func _on_dialog_ended():
	hide()

func update_dialog(dialog_data: Dictionary):
	text_label.text = dialog_data.get("text", "")
	npc_name_label.text = dialog_data.get("npc_name", "NPC")  # 可在 JSON 中添加 npc_name 字段
	
	# 清除旧选项
	for child in options_container.get_children():
		child.queue_free()
	
	# 创建新选项按钮
	var options = dialog_data.get("options", [])
	for i in range(options.size()):
		var opt = options[i]
		var btn = Button.new()
		btn.text = opt.get("text", "选项")
		btn.pressed.connect(_on_option_selected.bind(i))
		options_container.add_child(btn)

func _on_option_selected(option_index: int):
	GameDialogManager.select_option(option_index)
