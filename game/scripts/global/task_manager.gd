# task_manager.gd
# 任务管理器单例（Autoload）
# 负责：
#   - 加载和管理任务定义（tasks.json）
#   - 追踪所有任务的状态和进度
#   - 焦点任务系统
#   - 任务排序/过滤
#   - 发射信号供 UI 刷新

extends Node

# ======================== 信号 ========================
signal tasks_updated()                    # 任何任务状态变化时发射
signal focus_task_changed(task_id: String) # 焦点任务变化时发射
signal task_completed(task_id: String)     # 某任务完成时发射

# ======================== 常量 ========================
const TASKS_DATA_PATH: String = "res://data/tasks.json"

# ======================== 任务状态 ========================
enum TaskStatus { NOT_STARTED, IN_PROGRESS, COMPLETED }

# 任务运行时数据：id -> { status, progress, trigger_time, completed_time }
var _task_states: Dictionary = {}

# 任务定义：id -> TaskData
var _task_definitions: Dictionary = {}

# ======================== 焦点任务 ========================
var _focus_task_id: String = ""
var auto_select_focus: bool = true

# ======================== 排序/过滤设置 ========================
enum SortMode { TRIGGER_TIME, PROGRESS }
enum FilterMode { ALL, IN_PROGRESS, COMPLETED }

var sort_mode: int = SortMode.TRIGGER_TIME
var filter_mode: int = FilterMode.ALL

# ======================== 初始化 ========================
func _ready():
	_load_task_definitions()
	_init_all_tasks()

func _load_task_definitions():
	if not FileAccess.file_exists(TASKS_DATA_PATH):
		push_error("任务定义文件不存在: ", TASKS_DATA_PATH)
		return
	
	var file = FileAccess.open(TASKS_DATA_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		push_error("任务定义 JSON 解析失败: ", json.get_error_message())
		return
	
	var data = json.get_data()
	if not data.has("tasks"):
		push_error("任务定义 JSON 缺少 'tasks' 根节点")
		return
	
	var raw_tasks = data["tasks"]
	for task_id in raw_tasks.keys():
		var task_dict = raw_tasks[task_id]
		task_dict["id"] = task_id
		_task_definitions[task_id] = TaskData.new(task_dict)
	
	print("成功加载 ", _task_definitions.size(), " 个任务定义")

func _init_all_tasks():
	for task_id in _task_definitions.keys():
		if not _task_states.has(task_id):
			_task_states[task_id] = {
				"status": TaskStatus.NOT_STARTED,
				"progress": 0,
				"trigger_time": 0.0,
				"completed_time": 0.0
			}

# ======================== 任务定义查询 ========================
func get_task_data(task_id: String) -> TaskData:
	return _task_definitions.get(task_id, null)

func get_all_task_definitions() -> Dictionary:
	return _task_definitions.duplicate()

# ======================== 任务状态管理 ========================
func get_task_status(task_id: String) -> int:
	if _task_states.has(task_id):
		return _task_states[task_id]["status"]
	return TaskStatus.NOT_STARTED

func get_task_progress(task_id: String) -> int:
	if _task_states.has(task_id):
		return _task_states[task_id]["progress"]
	return 0

func get_task_max_progress(task_id: String) -> int:
	var def = get_task_data(task_id)
	return def.max_progress if def else 1

# 开始任务
func start_task(task_id: String):
	if not _task_states.has(task_id):
		return
	if _task_states[task_id]["status"] != TaskStatus.NOT_STARTED:
		return
	
	_task_states[task_id]["status"] = TaskStatus.IN_PROGRESS
	_task_states[task_id]["trigger_time"] = GameClock.get_total_seconds() if GameClock else 0.0
	
	if _focus_task_id.is_empty():
		_set_focus_task(task_id)
	
	tasks_updated.emit()

# 更新任务进度
func update_progress(task_id: String, progress: int):
	if not _task_states.has(task_id):
		return
	
	var def = get_task_data(task_id)
	if not def:
		return
	
	var max_prog = def.max_progress
	var new_progress = mini(progress, max_prog)
	
	if _task_states[task_id]["status"] == TaskStatus.NOT_STARTED:
		_task_states[task_id]["status"] = TaskStatus.IN_PROGRESS
		_task_states[task_id]["trigger_time"] = GameClock.get_total_seconds() if GameClock else 0.0
	
	_task_states[task_id]["progress"] = new_progress
	
	if new_progress >= max_prog:
		_complete_task_internal(task_id)
	
	tasks_updated.emit()

func add_progress(task_id: String, amount: int = 1):
	var current = get_task_progress(task_id)
	update_progress(task_id, current + amount)

func complete_task(task_id: String):
	update_progress(task_id, get_task_max_progress(task_id))

func _complete_task_internal(task_id: String):
	if _task_states[task_id]["status"] == TaskStatus.COMPLETED:
		return
	
	_task_states[task_id]["status"] = TaskStatus.COMPLETED
	_task_states[task_id]["completed_time"] = GameClock.get_total_seconds() if GameClock else 0.0
	
	task_completed.emit(task_id)
	
	if _focus_task_id == task_id:
		if auto_select_focus:
			_auto_select_next_focus()
		else:
			_clear_focus_task()

# 获取已完成任务列表（供存档使用）
func get_completed_tasks() -> Array:
	var result = []
	for tid in _task_states:
		if _task_states[tid]["status"] == TaskStatus.COMPLETED:
			result.append(tid)
	return result

# 获取所有进行中任务列表
func get_in_progress_tasks() -> Array:
	var result = []
	for tid in _task_states:
		if _task_states[tid]["status"] == TaskStatus.IN_PROGRESS:
			result.append(tid)
	return result

# 设置已完成任务列表（供读档使用）
func set_completed_tasks(tasks: Array):
	_init_all_tasks()
	for tid in tasks:
		if _task_states.has(tid):
			_task_states[tid]["status"] = TaskStatus.COMPLETED
			_task_states[tid]["progress"] = get_task_max_progress(tid)
	tasks_updated.emit()

# ======================== 获取任务列表（支持过滤和排序） ========================
func get_filtered_tasks() -> Array:
	var result = []
	
	for tid in _task_definitions.keys():
		var def = _task_definitions[tid]
		if def.hidden:
			continue
		
		var state = _task_states.get(tid, {})
		var status = state.get("status", TaskStatus.NOT_STARTED)
		
		match filter_mode:
			FilterMode.IN_PROGRESS:
				if status != TaskStatus.IN_PROGRESS:
					continue
			FilterMode.COMPLETED:
				if status != TaskStatus.COMPLETED:
					continue
		
		result.append(tid)
	
	match sort_mode:
		SortMode.TRIGGER_TIME:
			result.sort_custom(func(a, b): return _compare_by_trigger_time(a, b))
		SortMode.PROGRESS:
			result.sort_custom(func(a, b): return _compare_by_progress(a, b))
	
	return result

func _compare_by_trigger_time(a: String, b: String) -> bool:
	var ta = _task_states.get(a, {}).get("trigger_time", 0.0)
	var tb = _task_states.get(b, {}).get("trigger_time", 0.0)
	if ta == 0.0 and tb == 0.0:
		return a < b
	if ta == 0.0:
		return false
	if tb == 0.0:
		return true
	return ta < tb

func _compare_by_progress(a: String, b: String) -> bool:
	var pa = _task_states.get(a, {}).get("progress", 0)
	var pb = _task_states.get(b, {}).get("progress", 0)
	if pa != pb:
		return pa > pb
	return _compare_by_trigger_time(a, b)

# ======================== 焦点任务系统 ========================
func get_focus_task_id() -> String:
	return _focus_task_id

func get_focus_task_data() -> TaskData:
	if _focus_task_id.is_empty():
		return null
	return _task_definitions.get(_focus_task_id, null)

func get_focus_task_progress() -> int:
	if _focus_task_id.is_empty():
		return 0
	return get_task_progress(_focus_task_id)

func get_focus_task_max_progress() -> int:
	if _focus_task_id.is_empty():
		return 0
	return get_task_max_progress(_focus_task_id)

func toggle_focus_task(task_id: String) -> bool:
	if task_id == _focus_task_id:
		_clear_focus_task()
		return true
	
	if _task_states.get(task_id, {}).get("status", TaskStatus.NOT_STARTED) != TaskStatus.IN_PROGRESS:
		return false
	
	_set_focus_task(task_id)
	return true

func _set_focus_task(task_id: String):
	if _focus_task_id == task_id:
		return
	_focus_task_id = task_id
	focus_task_changed.emit(task_id)
	tasks_updated.emit()

func _clear_focus_task():
	if _focus_task_id.is_empty():
		return
	_focus_task_id = ""
	focus_task_changed.emit("")
	tasks_updated.emit()

func _auto_select_next_focus():
	var in_progress = get_in_progress_tasks()
	if in_progress.is_empty():
		_clear_focus_task()
		return
	
	var best = in_progress[0]
	var best_progress = -1
	for tid in in_progress:
		var p = get_task_progress(tid)
		if p > best_progress:
			best_progress = p
			best = tid
	
	_set_focus_task(best)

# ======================== 排序/过滤模式切换 ========================
func set_filter_mode(mode: int):
	filter_mode = mode
	tasks_updated.emit()

func set_sort_mode(mode: int):
	sort_mode = mode
	tasks_updated.emit()

# ======================== 重置 ========================
func reset():
	_focus_task_id = ""
	_task_states.clear()
	_init_all_tasks()
	sort_mode = SortMode.TRIGGER_TIME
	filter_mode = FilterMode.ALL
	auto_select_focus = true
	tasks_updated.emit()

# ======================== 存档/读档支持 ========================
# 获取所有任务状态（供存档使用）
func get_all_task_states() -> Dictionary:
	return _task_states.duplicate(true)

# 从存档恢复任务状态
func restore_task_states(states: Dictionary):
	_task_states.clear()
	for task_id in _task_definitions.keys():
		if states.has(task_id):
			_task_states[task_id] = states[task_id].duplicate()
		else:
			_task_states[task_id] = {
				"status": TaskStatus.NOT_STARTED,
				"progress": 0,
				"trigger_time": 0.0,
				"completed_time": 0.0
			}
	tasks_updated.emit()

# ======================== 工具方法 ========================
func get_status_text(task_id: String) -> String:
	var status = get_task_status(task_id)
	match status:
		TaskStatus.NOT_STARTED: return "未开始"
		TaskStatus.IN_PROGRESS: return "进行中"
		TaskStatus.COMPLETED:   return "已完成"
	return "未知"

func get_progress_text(task_id: String) -> String:
	return str(get_task_progress(task_id)) + "/" + str(get_task_max_progress(task_id))
