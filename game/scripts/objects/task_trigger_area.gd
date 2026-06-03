# task_trigger_area.gd
# 任务触发区域：玩家进入该区域时触发任务进度更新或任务完成

extends Area2D

# 要触发的任务ID
@export var task_id: String = "arrive_library"
# 触发后设置的进度值（达到 max_progress 时自动完成）
@export var set_progress: int = 1
# 触发后是否自动开始任务（如果任务尚未开始）
@export var auto_start: bool = true
# 是否只触发一次
@export var one_shot: bool = true
# 触发后是否显示提示
@export var show_message: bool = true
# 触发提示文字
@export var message: String = "任务完成！"

# 内部状态
var _triggered: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	
	# 如果没有纹理，生成一个半透明绿色方块作为可视化提示
	if $DebugSprite and not $DebugSprite.texture:
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.3, 0.8, 0.3, 0.4))
		var tex = ImageTexture.create_from_image(image)
		$DebugSprite.texture = tex

func _on_body_entered(body: Node):
	if _triggered and one_shot:
		return
	
	if body == InteractionManager.player:
		_triggered = true
		
		# 自动开始任务
		if auto_start:
			TaskManager.start_task(task_id)
		
		# 设置进度
		TaskManager.update_progress(task_id, set_progress)
		
		if show_message:
			var task_data = TaskManager.get_task_data(task_id)
			var task_name = task_data.name if task_data else task_id
			print("任务触发: ", task_name, " 进度: ", set_progress)
		
		# 如果是单次触发，隐藏可视化提示
		if one_shot and $DebugSprite:
			$DebugSprite.visible = false
