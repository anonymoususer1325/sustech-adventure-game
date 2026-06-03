extends "res://scripts/components/npc.gd"

func interact():
	super.interact()
	if not InventoryManager.has_item("pencil"):
		InventoryManager.add_item("pencil")
		print("获得铅笔！")
