# 🏫 SUSTech Adventure Game

南科大校园冒险游戏 — 一款基于 **Godot 4** 引擎开发的 2D 俯视角校园探索游戏。

[![Godot 4.6](https://img.shields.io/badge/Godot-4.6-478cbf?logo=godot-engine)](https://godotengine.org/)
[![GDScript](https://img.shields.io/badge/Language-GDScript-355570)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 📖 游戏简介

你是一名南科大新生，需要在 **10 分钟**倒计时内，在校园各处收集物资（学生证、借阅卡、便条、荔枝），最终送到教学楼完成交付。沿途与 NPC 对话获取线索，探索多个互连的校园场景。

### 核心特性

| 特性 | 描述 |
|------|------|
| 🗺️ **多场景地图** | 5 个互连场景：南门、中心广场、图书馆、宿舍、教学楼 |
| 🚪 **传送系统** | 场景间无缝传送，带光照过渡动画 |
| 🎒 **物品收集** | 背包系统，实时进度追踪，支持堆叠/非堆叠物品 |
| 💬 **NPC 对话** | 多轮对话树，选项影响对话走向 |
| 📋 **任务系统** | 焦点任务 HUD，进度实时显示，自动接取后续任务 |
| ⏱️ **倒计时** | 10 分钟倒计时（基于系统时钟），超时游戏失败 |
| 💾 **存档系统** | 4 个存档槽位，完整保存位置/背包/任务/时间 |
| 🏆 **通关画面** | 收集完物资并交付后显示胜利界面 |

---

## 🚀 快速开始

### 环境要求

- [Godot 4.6+](https://godotengine.org/download)（推荐使用标准版，GL Compatibility 渲染模式）

### 运行游戏

```bash
# 1. 克隆仓库
git clone <your-repo-url>
cd game

# 2. 用 Godot 打开项目
godot --editor project.godot

# 3. 或直接运行
godot --path . project.godot
```

### 导出可执行文件

在 Godot 编辑器中：**项目 → 导出** → 选择目标平台（Windows/Linux/macOS/Web）→ 导出。

---

## 🎮 操作指南

| 按键 | 功能 |
|------|------|
| `W/A/S/D` 或 方向键 | 移动角色 |
| `Shift` | 奔跑 |
| `E / Space / Z` | 交互（对话/拾取/进入教室） |
| `I` | 打开/关闭背包 |
| `J` | 打开/关闭任务面板 |
| `Esc / X` | 关闭 UI / 暂停菜单 |

---

## 🗺️ 场景结构

```
campus_LH3_sou ─── campus_LH3_mid ─── campus_library
      │                    │
      ▼                    ▼
campus_dormitory    campus_teaching
```

---

## 📁 项目结构

```
game/
├── assets/          # 美术资源（角色、字体、瓷砖集、贴图）
├── data/            # JSON 数据文件（物品、任务、对话）
├── scenes/
│   ├── characters/  # 玩家角色场景
│   ├── levels/      # 关卡场景（5 个地图）
│   ├── objects/     # 可拾取物品、NPC、传送门等
│   └── ui/          # UI 场景（主菜单、背包、任务、对话等）
└── scripts/
    ├── characters/  # 玩家控制脚本
    ├── components/  # 可交互组件（NPC、传送门）
    ├── data/        # 数据模型
    ├── global/      # 全局管理器（Autoload 单例）
    ├── levels/      # 关卡逻辑
    ├── objects/     # 交互对象脚本
    └── ui/          # UI 控制脚本
```

---

## 游戏截图

![image-20260605213638529](C:\Users\周可\AppData\Roaming\Typora\typora-user-images\image-20260605213638529.png)

![image-20260605213707622](C:\Users\周可\AppData\Roaming\Typora\typora-user-images\image-20260605213707622.png)![image-20260605213818375](C:\Users\周可\AppData\Roaming\Typora\typora-user-images\image-20260605213818375.png)

## ⚠️ 已知问题

- 地图装饰层（Deco/Props/Buildings）尚未完整铺设，仅 Ground 层可用
- 碰撞边界需要在编辑器中手动绘制
- 无音频系统（BGM/SFX）
- 多人模式仅为 UI 占位

---

## 📄 许可证

MIT License

