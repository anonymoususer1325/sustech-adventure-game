# 存档数据格式说明
# 版本历史：
#   v1 - 初始版本，包含玩家位置、任务完成列表、背包物品
#
# 数据结构：
# {
#     "version": int,              # 存档版本号，当前为 1
#     "scene_path": String,        # 当前场景的资源路径
#     "player_x": float,           # 玩家 X 坐标
#     "player_y": float,           # 玩家 Y 坐标
#     "completed_tasks": Array,    # 已完成任务 ID 列表，元素为 String
#     "inventory": Array           # 背包物品列表，每个元素为 { "id": String, "count": int }
# }
const SAVE_VERSION = 1

# 创建新的存档数据（默认值）
static func new_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"scene_path": "",
		"player_x": 0.0,
		"player_y": 0.0,
		"completed_tasks": [],
		"inventory": []
	}
