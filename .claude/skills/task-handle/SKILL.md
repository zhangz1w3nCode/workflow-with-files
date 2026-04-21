---
name: task-handle
description: 工作流执行监督系统。通过 hooks 在每次工具调用前注入当前进度，确保 AI 不会忘记当前节点和任务目标。
user-invocable: false
allowed-tools: "Read Write Edit Bash Glob Grep"
hooks:
  UserPromptSubmit:
    - hooks:
        - type: command
          command: "for f in $(find .claude/workflows -path '*/instance/*/PROGRESS.md' -type f 2>/dev/null | head -1); do echo '[task-handle] 检测到活跃实例。如本次对话中尚未读取，请立即读取该实例的 PROGRESS.md 和 ARTIFACTS.md。'; done"
  PreToolUse:
    - matcher: "Write|Edit|Bash|Read|Glob|Grep"
      hooks:
        - type: command
          command: "for f in $(find .claude/workflows -path '*/instance/*/PROGRESS.md' -type f 2>/dev/null | head -1); do echo '[task-handle] === 当前进度 ==='; cat \"$f\" | head -40; echo ''; done || true"
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "for f in $(find .claude/workflows -path '*/instance/*/PROGRESS.md' -type f 2>/dev/null | head -1); do dir=$(dirname \"$f\"); echo \"[task-handle] 文件已更新。产物必须保存到当前实例目录: $dir/artifacts/{节点名}/。同时更新 PROGRESS.md（节点状态）和 ARTIFACTS.md（产物清单）。\"; done"
  Stop:
    - hooks:
        - type: command
          command: "for f in $(find .claude/workflows -path '*/instance/*/PROGRESS.md' -type f 2>/dev/null | head -1); do total=$(grep -cE '^\| [0-9]+ \|' \"$f\" 2>/dev/null || echo 0); complete=$(grep -cE '\| complete \|' \"$f\" 2>/dev/null || echo 0); echo \"[task-handle] 进度: $complete/$total 节点完成。请确保该实例的 PROGRESS.md 和 ARTIFACTS.md 已保存，以便下次恢复。\"; done || true"
---

# 工作流监督系统

本 skill 不直接响应用户命令，而是通过 hooks 在 AI 执行工作流时注入进度上下文。

## 入口命令

- `/task-handle-instance <需求描述>` — 创建新实例并开始工作流
- `/task-handle-continue [实例ID]` — 继续已有实例

## 监督文件

所有状态记录在实例目录下的两个 Markdown 文件中：

```
.claude/workflows/{name}/instance/{timestamp-id}/
    ├── PROGRESS.md          ← 唯一状态源
    ├── ARTIFACTS.md         ← 产物中心（产物清单 + 节点结论）
    └── artifacts/           ← 产物文件必须放在这里
        └── {节点名}/
            └── ...          ← 禁止将产物写到项目根目录或其他位置
```

## Hooks 行为

| Hook | 触发时机 | 作用 |
|------|---------|------|
| UserPromptSubmit | 每次发消息前 | 检测活跃实例，提醒读取 PROGRESS.md/ARTIFACTS.md |
| PreToolUse | 每次调用工具前 | **直接注入 PROGRESS.md 前40行到上下文**，让 AI 始终知道当前节点 |
| PostToolUse | 写/编辑文件后 | 提醒更新进度和产物文件 |
| Stop | 会话结束时 | 从 PROGRESS.md 解析并报告完成度 |
