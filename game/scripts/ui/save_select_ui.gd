# SaveSelectUI.gd
extends Control

const SLOT_COUNT = 4
var slots: Array = []

@onready var grid = $SavesGridContainer

func _ready():
	for i in range(SLOT_COUNT):
		var slot = preload("res://scenes/ui/save_slot.tscn").instantiate()
		grid.add_child(slot)
		slots.append(slot)
		slot.set_slot_index(i)
		slot.slot_action.connect(_on_slot_action)
		update_slot_display(i)
	call_deferred("_set_initial_focus")

func _set_initial_focus():
	if slots.size() > 0:
		slots[0].info_button.grab_focus()

func update_slot_display(slot: int):
	var metadata = SaveManager.get_save_metadata(slot)
	var is_empty = metadata.is_empty()
	slots[slot].set_empty(is_empty)
	if not is_empty:
		slots[slot].set_info(metadata)

func _on_slot_action(slot: int, action: String):
	if action == "read":
		SaveManager.load_game(slot)
	elif action == "delete":
		var path = SaveManager.get_save_path(slot)
		DirAccess.remove_absolute(path)
		update_slot_display(slot)
		# 刷新后，该存档位应自动回到信息模式（已在 save_slot 中调用 switch_mode(Mode.INFO)）

func get_first_focusable() -> Control:
	if slots.size() > 0:
		return slots[0].get_info_button()
	return null
