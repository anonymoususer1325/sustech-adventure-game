# delivery_door.gd
# 教室入口交互点 — 检查物资是否集齐
extends Interactable

@onready var _hint_label: Label = $Label
var _hint_timer: float = 0.0

func _ready():
	super._ready()
	if _hint_label:
		_hint_label.text = "🚪 教室入口"

func _on_focus_changed(focused: bool):
	if _hint_label:
		_hint_label.visible = focused

func _process(delta):
	if _hint_timer > 0:
		_hint_timer -= delta
		if _hint_timer <= 0:
			if _hint_label:
				_hint_label.text = "🚪 教室入口"

func interact():
	super.interact()
	
	var has_all = InventoryManager.has_item("student_card") and \
	              InventoryManager.has_item("library_card") and \
	              InventoryManager.has_item("note") and \
	              InventoryManager.has_item("pencil")
	
	if has_all:
		if TaskManager.get_task_status("deliver_to_teaching") == TaskManager.TaskStatus.IN_PROGRESS:
			TaskManager.complete_task("deliver_to_teaching")
	else:
		# 显示提示文字，3秒后恢复
		if _hint_label:
			_hint_label.text = "❌ 物资不全！需要：学生证、借阅卡、便条、铅笔"
			_hint_timer = 3.0
