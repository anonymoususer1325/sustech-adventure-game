# backpack_ui.gd
# 背包 UI 场景脚本
# 显示物品网格、详情面板和使用按钮。
# 通过 InventoryManager.inventory_updated 信号自动刷新。

extends Control

# ======================== 常量 ========================
const GRID_COLUMNS: int = 4

# ======================== 节点引用 ========================
@onready var grid_container: GridContainer = $CenterContainer/Background/GridContainer
@onready var item_name_label: Label = $CenterContainer/Background/DetailPanel/ItemName
@onready var item_desc_label: Label = $CenterContainer/Background/DetailPanel/ItemDescription
@onready var item_count_label: Label = $CenterContainer/Background/DetailPanel/ItemCount
@onready var use_button: Button = $CenterContainer/Background/DetailPanel/UseButton
@onready var close_button: Button = $CenterContainer/Background/CloseButton
@onready var empty_hint: Label = $CenterContainer/Background/EmptyHint
@onready var background: Panel = $CenterContainer/Background

# ======================== 状态 ========================
# 当前显示的物品槽位节点列表
var _slot_nodes: Array = []
# 当前选中的槽位索引（-1 = 无选中）
var _selected_index: int = -1

# ======================== 生命周期 ========================
func _ready():
	# 初始隐藏
	visible = false
	
	# 连接信号
	InventoryManager.inventory_updated.connect(_on_inventory_updated)
	GameDialogManager.dialog_started.connect(_on_dialog_started)
	close_button.pressed.connect(_close)
	use_button.pressed.connect(_on_use_pressed)
	
	# 初始刷新
	_refresh()

# 对话开始时自动关闭背包
func _on_dialog_started(_dialog_data: Dictionary, _npc: Node):
	if visible:
		close()

# ======================== 打开 / 关闭 ========================
func open():
	_refresh()
	visible = true
	_focus_first_slot()
	get_tree().paused = true

func close():
	visible = false
	get_tree().paused = false

func _close():
	close()

func toggle():
	if visible:
		close()
	else:
		open()

# ======================== 刷新背包 ========================
func _on_inventory_updated():
	_refresh()

func _refresh():
	# 清空旧槽位
	for slot in _slot_nodes:
		slot.queue_free()
	_slot_nodes.clear()
	_selected_index = -1
	
	var items = InventoryManager.get_items()
	
	if items.is_empty():
		empty_hint.visible = true
		grid_container.visible = false
		_clear_detail_panel()
		use_button.disabled = true
		return
	
	empty_hint.visible = false
	grid_container.visible = true
	use_button.disabled = false
	
	# 为每个物品创建槽位
	for i in range(items.size()):
		var entry = items[i]
		var slot = _create_slot(entry, i)
		grid_container.add_child(slot)
		_slot_nodes.append(slot)
	
	# 选中第一个物品
	_select_slot(0)

# 创建一个物品槽位
func _create_slot(entry: Dictionary, index: int) -> Button:
	var item_id = entry["id"]
	var count = entry["count"]
	var item_data = InventoryManager.get_item_data(item_id)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.tooltip_text = item_data.name if item_data else item_id
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# 垂直布局：图标上方，数量下方
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn.add_child(vbox)
	
	# 图标（先用文字占位，后续可用 TextureRect）
	var icon_label = Label.new()
	icon_label.text = _get_item_emoji(item_id)  # 用 emoji 暂代图标
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(icon_label)
	
	# 物品数量
	var count_label = Label.new()
	count_label.text = "x" + str(count)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(count_label)
	
	# 选中样式（按下时高亮）
	btn.pressed.connect(_on_slot_pressed.bind(index))
	
	# 焦点进入时选中
	btn.focus_entered.connect(_on_slot_focus_entered.bind(index))
	
	return btn

# 用 emoji 暂代物品图标（后续可替换为真实图标）
func _get_item_emoji(item_id: String) -> String:
	match item_id:
		"student_card": return "🪪"
		"phone": return "📱"
		"radar": return "📡"
		"lychee": return "🍒"
		"library_card": return "📚"
		"key": return "🔑"
		"note": return "📝"
		"speed_boost": return "💨"
		"invisibility": return "👻"
		_: return "📦"

# ======================== 选中逻辑 ========================
func _select_slot(index: int):
	if index < 0 or index >= _slot_nodes.size():
		_selected_index = -1
		_clear_detail_panel()
		return
	
	_selected_index = index
	
	# 更新详情面板
	var items = InventoryManager.get_items()
	if index >= items.size():
		return
	
	var entry = items[index]
	var item_id = entry["id"]
	var count = entry["count"]
	var item_data = InventoryManager.get_item_data(item_id)
	
	if item_data:
		item_name_label.text = item_data.name
		item_desc_label.text = item_data.description
		item_count_label.text = "持有数量: " + str(count)
		use_button.disabled = not item_data.is_usable()
	else:
		item_name_label.text = item_id
		item_desc_label.text = "（未知物品）"
		item_count_label.text = "持有数量: " + str(count)
		use_button.disabled = true

func _clear_detail_panel():
	item_name_label.text = ""
	item_desc_label.text = ""
	item_count_label.text = ""
	use_button.disabled = true

func _on_slot_pressed(index: int):
	_select_slot(index)

func _on_slot_focus_entered(index: int):
	_select_slot(index)

func _focus_first_slot():
	if _slot_nodes.size() > 0:
		_slot_nodes[0].grab_focus()
	else:
		close_button.grab_focus()

# ======================== 键盘导航 ========================
func _input(event):
	if not visible:
		return
	
	# ESC 关闭
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
		return
	
	# 方向键导航（如果当前没有选中任何槽位，不处理）
	if _selected_index < 0:
		return
	
	var cols = GRID_COLUMNS
	var total = _slot_nodes.size()
	
	if event.is_action_pressed("ui_right"):
		var next = min(_selected_index + 1, total - 1)
		_slot_nodes[next].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		var prev = max(_selected_index - 1, 0)
		_slot_nodes[prev].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		var next = min(_selected_index + cols, total - 1)
		_slot_nodes[next].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		var prev = max(_selected_index - cols, 0)
		_slot_nodes[prev].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		# 确认键触发使用
		_on_use_pressed()
		get_viewport().set_input_as_handled()

# ======================== 使用物品 ========================
func _on_use_pressed():
	if _selected_index < 0 or _selected_index >= _slot_nodes.size():
		return
	
	var items = InventoryManager.get_items()
	if _selected_index >= items.size():
		return
	
	var item_id = items[_selected_index]["id"]
	print("使用物品: ", item_id)
	
	var success = InventoryManager.use_item(item_id, 1)
	if success:
		print("成功使用物品: ", item_id)
		# 背包已通过 inventory_updated 信号自动刷新
	else:
		print("使用物品失败: ", item_id)

# ======================== 获取焦点控件（供暂停菜单等使用） ========================
func get_first_focusable() -> Control:
	if _slot_nodes.size() > 0:
		return _slot_nodes[0]
	return close_button
