# Final Report — Team 26

> **项目名称**: SUSTech Adventure Game（南科大校园冒险游戏）
> **团队编号**: Team 26
> **学期**: 2026 Spring

---

## 一、项目指标 (Metrics)

| 指标 | 数值 | 测算工具 |
|------|------|---------|
| **代码行数 (LOC)** | ~3,109 行 GDScript | PowerShell `Measure-Object` |
| **源文件数** | 36 GDScript + 25 TSCN + 3 JSON | PowerShell `Get-ChildItem` |
| **总文件数** | 259 | - |
| **圈复杂度** | 平均 2-5 / 函数，最高 ~8 | 人工审查 |
| **外部依赖** | 0（无 Godot 插件/Addon） | 项目无 `addons/` 目录 |

### 圈复杂度详情

| 文件 | 复杂度 | 原因 |
|------|--------|------|
| `game_level.gd` | ~8 | 任务链 + 倒计时 + 物品检测 |
| `task_manager.gd` | ~6 | 任务状态机 + 排序/过滤 |
| `inventory_manager.gd` | ~5 | 堆叠逻辑 + 多种 use_effect 分支 |
| 其余文件 | 2-4 | 单功能控制器/组件 |

---

## 二、CI/CD Pipeline

### 流水线配置

- **CI 工具**: GitHub Actions
- **配置路径**: `.github/workflows/ci.yml`
- **触发器**: push / pull request 到 main、master、release/* 分支
- **运行地址**: Fork 到个人仓库 (https://github.com/anonymoususer1325/sustech-adventure-game) 运行（组织仓库 Actions 配额已满）

### 流水线步骤

```
Push/PR → Checkout → Lint (JSON) → Test (场景) → Package (zip) → Upload
```

| 步骤 | 工具 | 说明 |
|------|------|------|
| **1. Checkout** | `actions/checkout@v4` | 拉取代码 |
| **2. JSON 验证** | `python3 -m json.tool` | 验证 items.json / tasks.json / dialogs.json 格式正确 |
| **3. 场景检查** | Shell `[ -f ]` | 验证 7 个关键 `.tscn` 场景文件存在 |
| **4. 代码统计** | `find` + `wc` | 统计 GDScript 文件数和代码行数 |
| **5. Package** | `zip` | 打包 `game/` 目录为 `sustech-adventure.zip` 可运行 artifact |
| **6. Upload** | `actions/upload-artifact@v4` | 上传构建产物 + 测试报告 |

### 测试内容

| 测试类型 | 方法 | 覆盖范围 |
|---------|------|---------|
| JSON 语法 | `python3 -m json.tool` | 3 个 JSON 数据文件 |
| 场景完整性 | Shell 文件存在检查 | 5 个关卡 + 主菜单 + 玩家场景 |
| 代码量 | `find . -name "*.gd"` | 36 个脚本文件 |

### 运行证明

流水线已通过 `anonymoususer1325/sustech-adventure-game` 个人仓库验证，Run #5 成功：
- Lint & Test ✅ 通过（JSON 验证 + 场景检查 + 代码统计）
- Package ✅ 通过（生成 `sustech-adventure.zip` artifact）
- 总耗时：24 秒
- ![image-20260605213940506](C:\Users\周可\AppData\Roaming\Typora\typora-user-images\image-20260605213940506.png)

> ⚠️ 由于 sustech-cs304 组织账户配额限制，CI 在 Fork 后的个人公开仓库运行。配置文件同步存在于组织仓库的 `.github/workflows/ci.yml`。

---

## 三、AI 使用声明 (AI Usage)

本项目使用 GitHub Copilot 完成以下工作：

| 类别 | AI 协助内容 | 人工审核方式 |
|------|-----------|-------------|
| **代码** | 任务链逻辑、传送门、交付点、倒计时、NPC 交互 | 每段 AI 代码均经过编译验证和运行测试 |
| **文档** | README.md、团队报告 | 人工补充截图和校对 |
| **测试** | 自动化测试脚本（JSON/场景/Autoload 验证） | 确认测试覆盖关键路径 |
| **指标** | 代码行数统计、复杂度估算 | 使用 PowerShell 验证 |
| **CI/CD** | GitHub Actions 工作流配置 | 在仓库中实际触发验证 |

AI 使用问卷（每队一份）：[填写链接](https://wj.qq.com/s2/26420852/rjn4/)

---

## 四、功能演示清单

### Feature 1: 多场景传送系统
- **5 个互连场景**: 南门 (LH3_sou)、中心广场 (LH3_mid)、图书馆、宿舍、教学楼
- **传送机制**: 基于 Area2D 的碰撞检测，含光照收缩/展开过渡动画
- **北方向量**: 每个场景独立设置，传送时自动旋转玩家朝向

### Feature 2: 物品收集与背包
- **4 种主线物品**: 学生证（宿舍）、借阅卡（图书馆）、便条（中心广场）、铅笔（教学楼）
- **背包 UI**: 按 I 打开，4 列网格布局，含详情面板和使用按钮
- **栈叠系统**: 支持堆叠/非堆叠两种类型，栈叠上限可配置

### Feature 3: NPC 对话系统
- **多轮对话树**: 基于 JSON 数据驱动，支持多选项分支
- **场景角色**: 5 个 NPC 分布各场景（热心同学、图书管理员、宿管阿姨、教学楼管理员）
- **对话锁**: 对话期间锁定玩家移动和交互

### Feature 4: 任务系统
- **2 个主线任务**: 收集物资（4 件）→ 教学楼交付
- **实时进度**: 物品拾取即时刷新任务进度（0/4 → 1/4 → …）
- **焦点提示**: HUD 显示当前任务名称和进度

### Feature 5: 倒计时挑战
- **10 分钟限时**: 基于系统时钟 Tick（跨场景不重置）
- **暂停机制**: 暂停菜单和背包打开时停止计时
- **荔枝延长时间**: 使用荔枝道具 +60 秒
- **超时失败**: 显示失败画面，可返回主菜单重试

### Feature 6: 存档系统
- **4 个存档槽位**: 独立文件存储
- **完整保存内容**: 玩家位置、朝向、背包物品、任务状态、游玩时间、当前场景
- **读档恢复**: 保留所有游戏进度，倒计时从存档时间继续

### 非功能特性 (Non-functional)

- **系统时钟计时**: `GameClock` 使用 `Time.get_ticks_msec()` 避免 `_process` 不触发的问题
- **NPC 可重复对话**: 教学楼 NPC 对话后自动注销，其他 NPC 可多次对话
- **场景常驻 HUD**: 倒计时使用独立场景 `CountdownHud`，每帧刷新
- **资源管理**: 所有美术资源仅使用已有图片（Ground.png 等），无需外部下载
