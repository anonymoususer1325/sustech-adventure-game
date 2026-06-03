# Final Report — Team 26

> **项目名称**: SUSTech Adventure Game（南科大校园冒险游戏）
> **团队编号**: Team 26
> **学期**: 2026 Spring

---

## 一、项目指标 (Metrics)

| 指标 | 数值 |
|------|------|
| **GDScript 代码行数** | ~3,000 |
| **源文件数** | 32 个 GDScript + 24 个场景 + 3 个 JSON |
| **总文件数** | 248 |
| **圈复杂度（估算）** | 平均 2-5/函数，最高 `game_level.gd` ~8 |
| **外部依赖** | 0（仅 Godot 4.6 引擎内置功能，无 addon/插件） |

### 圈复杂度说明

GDScript 函数普遍简短（5-15 行），复杂度集中在：
- `game_level.gd` — 任务链 + 倒计时（复杂度 ~8）
- `task_manager.gd` — 任务状态机 + 排序过滤（复杂度 ~6）
- `inventory_manager.gd` — 物品堆叠逻辑（复杂度 ~5）

### 数据来源

- 行数/文件数：PowerShell `Get-ChildItem` + `Measure-Object`
- 复杂度：人工审查
- 依赖：项目无 addon，依赖列表 = Godot 引擎内置功能

---

## 二、CI/CD Pipeline

### 流水线步骤

```
Push → Checkout → Setup Godot → Lint → Test → Export → Upload
```

| 步骤 | 工具/技术 | 说明 |
|------|----------|------|
| **Checkout** | `actions/checkout@v4` | 拉取代码 |
| **Setup Godot** | Godot CLI headless | 安装 Godot 4.3 无头版 |
| **Lint** | 自定义 GDScript 加载测试 | 验证所有 `.gd` 文件可正常加载 |
| **Test** | 自定义 SceneTree 测试 | 验证 JSON 数据解析、Autoload 单例存在 |
| **Export** | Godot --export-release | 导出 Windows/Linux/Web 三平台可执行文件 |
| **Upload** | `actions/upload-artifact@v4` | 上传构建产物为 GitHub Artifact |

### 配置文件

- 工作流文件：`.github/workflows/ci.yml`
- 测试脚本：`scripts/tests/run_tests.gd`
- Lint 脚本：`scripts/tests/run_lint.gd`

### 运行证明

流水线在 push 到 main 分支时自动触发，成功导出三个平台的可执行文件作为 artifact。

---

## 三、AI 使用声明 (AI Usage)

本项目使用 GitHub Copilot / AI 编程助手完成以下工作：

| 类别 | AI 协助内容 |
|------|------------|
| **文档** | README.md、团队报告、代码注释 |
| **测试** | 自动化测试脚本（JSON 解析验证、Autoload 检查） |
| **指标** | 代码行数统计、复杂度估算 |
| **CI/CD** | GitHub Actions 工作流配置 |

所有 AI 生成的代码均经过人工审查、修改和测试验证。

---

## 四、功能演示清单

### Feature 1: 多场景传送系统
- 5 个校园场景互连
- 带光照过渡动画的传送
- 双向传送门坐标对齐

### Feature 2: 物品收集与背包
- 4 种收集物品（学生证、借阅卡、便条、荔枝）
- 实时背包 UI（I 键打开）
- 堆叠/非堆叠物品支持

### Feature 3: NPC 对话系统
- 多轮对话树，3-4 个 NPC 各具特色
- 对话选项影响走向
- 对话中锁定移动

### Feature 4: 任务与进度追踪
- 2 个主要任务（收集物资 → 交付）
- 实时进度更新（拾取物品即时刷新）
- 焦点任务 HUD 显示

### Feature 5: 倒计时挑战
- 10 分钟系统时钟倒计时（不受场景切换影响）
- 暂停时停止计时
- 超时显示失败画面

### Feature 6: 存档系统
- 4 个存档槽位
- 完整保存：位置/背包/任务/时间/场景
- 读档恢复所有状态
