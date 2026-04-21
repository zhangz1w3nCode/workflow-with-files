# 文件化工作流

[English](README.md) | 中文

一个基于文件规划的 Claude Code 工作流系统，用于组织和跟踪复杂任务的进度。灵感来自 Manus 风格的规划方式。

## 概述

本项目通过以下方式提供结构化多步骤任务管理：

- **基于文件的规划**：任务被分解为节点，通过 Markdown 文件跟踪
- **进度跟踪**：通过 `PROGRESS.md` 实时监测进度
- **产物管理**：每个工作流实例有统一的产物存储中心
- **Hook 集成**：AI 执行期间自动注入上下文

## 项目结构

```
.claude/
├── nodes/                    # 工作流步骤的知识节点
├── skills/                   # Claude Code 技能
│   ├── task-handle/         # 工作流监督系统
│   ├── task-handle-continue/# 实例延续技能
│   └── task-handle-instance/# 实例创建技能
├── workflows/               # 工作流定义
│   └── {工作流名称}/
│       ├── meta-data/       # 工作流元数据
│       └── instance/        # 活跃工作流实例
│           └── {时间戳-id}/
│               ├── PROGRESS.md    # 状态唯一来源
│               ├── ARTIFACTS.md   # 产物清单 + 节点结论
│               └── artifacts/     # 按节点组织的产物文件
├── settings.local.json      # 本地 Claude Code 配置
└── .gitignore               # Git 忽略规则
```

## 技能

| 技能 | 描述 |
|------|------|
| `task-handle` | 工作流监督系统，通过 hooks 注入进度上下文 |
| `task-handle-instance` | 根据用户需求创建新工作流实例 |
| `task-handle-continue` | 恢复已有工作流实例 |

## 快速开始

1. 在 Claude Code 环境中激活技能
2. 使用 `/task-handle-instance <需求描述>` 启动工作流
3. 通过生成的 `PROGRESS.md` 跟踪进度
4. 使用 `/task-handle-continue [实例-id]` 稍后恢复

## 许可证

[MIT](LICENSE)
