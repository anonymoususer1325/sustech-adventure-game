# focus_task_hint.gd
# 游戏画面顶部的焦点任务提示 HUD
# 显示当前焦点任务名称和进度，以及任务完成提示

extends Control

@onready var task_name_label: Label = $Background/VBox/TaskName
@onready var progress_label: Label = $Background/VBox/Progress
@onready var background: Panel = $Background
@onready var complete_popup: Label = $CompletePopup
var countdown_label: Label = null

var _popup_timer: float = 0.0

func _ready():
	if not task_name_label:
		push_error("FocusTaskHint: task_name_label 未找到")
	if not progress_label:
		push_error("FocusTaskHint: progress_label 未找到")
	
	countdown_label = get_node_or_null("Background/VBox/Countdown") as Label
	
	TaskManager.focus_task_changed.connect(_on_focus_task_changed)
	TaskManager.tasks_updated.connect(_on_tasks_updated)
	TaskManager.task_completed.connect(_on_task_completed)
	
	complete_popup.visible = false
	
	# 直接用 Timer 每秒更新倒计时 — 比 _process 更可靠
	var timer = Timer.new()
	timer.name = "CountdownTimer"
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.timeout.connect(_on_countdown_tick)
	timer.one_shot = false
	add_child(timer)
	timer.start(0.5)
	
	_update_display()
	call_deferred("_update_display")

func _on_countdown_tick():
	var elapsed = GameClock.get_total_seconds()
	var remaining = max(0, 600.0 - elapsed)
	var minutes = int(remaining) / 60
	var seconds = int(remaining) % 60
	if countdown_label:
		countdown_label.text = "剩余: %02d:%02d" % [minutes, seconds]
		countdown_label.modulate = Color.RED if remaining <= 60 else Color.WHITE

func _process(delta):
	# 持续更新显示（确保状态同步）
	_update_display()
	
	if _popup_timer > 0:
		_popup_timer -= delta
		if _popup_timer <= 0:
			complete_popup.visible = false

func _on_focus_task_changed(_task_id: String):
	_update_display()

func _on_tasks_updated():
	_update_display()

func _on_task_completed(task_id: String):
	var def = TaskManager.get_task_data(task_id)
	if def:
		complete_popup.text = "✓ 任务完成: " + def.name
		complete_popup.visible = true
		_popup_timer = 3.0

func _update_display():
	# 始终更新倒计时（不受任务状态影响）
	var remaining = max(0, 600.0 - GameClock.get_total_seconds())
	var minutes = int(remaining) / 60
	var seconds = int(remaining) % 60
	var lbl = countdown_label if countdown_label else get_node_or_null("Background/VBox/Countdown")
	if lbl:
		lbl.text = "剩余: %02d:%02d" % [minutes, seconds]
		lbl.modulate = Color.RED if remaining <= 60 else Color.WHITE
	
	var focus_id = TaskManager.get_focus_task_id()
	
	if focus_id.is_empty():
		task_name_label.text = "探索校园吧！"
		progress_label.text = "按 J 查看任务"
		background.visible = true
		return
	
	var def = TaskManager.get_focus_task_data()
	if not def:
		task_name_label.text = "探索校园吧！"
		progress_label.text = "按 J 查看任务"
		background.visible = true
		return
	
	var cur = TaskManager.get_focus_task_progress()
	var max_p = TaskManager.get_focus_task_max_progress()
	
	task_name_label.text = def.name
	progress_label.text = str(cur) + "/" + str(max_p)
	
	background.visible = true
