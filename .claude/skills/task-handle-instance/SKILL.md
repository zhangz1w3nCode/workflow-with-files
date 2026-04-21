---
name: task-handle-instance
description: 创建新的工作流实例并开始执行任务。参数为用户的需求描述。示例：/task-handle-instance 帮我实现一个冒泡排序可视化页面
user-invocable: true
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

# 用户需求
$ARGUMENTS

# 工作流
- 位置：`.claude/workflows/标准流水线/WORKFLOW.md`

# 执行步骤

## 步骤 1: 创建新实例
运行初始化脚本创建工作流实例：

```bash
sh .claude/skills/task-handle/scripts/init-run.sh 标准流水线 "$ARGUMENTS"
```

脚本将输出实例ID和文件路径。

## 步骤 2: 读取工作流定义
读取 `.claude/workflows/标准流水线/WORKFLOW.md`，理解：
- 流程图中的节点顺序和依赖关系
- 每个节点对应的执行内容文件路径
- 强制事项和禁止事项

## 步骤 3: 读取进度文件
读取新创建的 `instance/{实例ID}/PROGRESS.md`，确认：
- 实例ID
- 任务摘要
- 当前节点: 未开始
- 状态: in_progress

## 步骤 4: 创建 TodoList
根据 WORKFLOW.md 中的节点列表，在上下文中创建 TodoList 跟踪所有节点。

## 步骤 5: 开始执行第一个节点
1. 确定第一个业务节点（跳过"开始"节点）
2. 更新 PROGRESS.md：将当前节点改为第一个节点，在"节点进度"表添加一行（状态 in_progress），在"执行日志"追加"进入节点"记录
3. 读取节点定义文件（如 `.claude/nodes/搜索记忆库.md`）
4. 执行节点任务
5. 节点完成后，更新 PROGRESS.md：
   - "节点进度"表中该节点状态改为 complete，填写完成时间
   - "当前状态"中当前节点改为"(刚完成 xxx)"
   - "执行日志"追加"完成节点"记录
6. 如有产物，更新 ARTIFACTS.md：
   - 在"节点产物汇总"下添加 `### {序号}-{节点名}` 章节
   - 列出产物文件清单
7. 继续下一个节点，循环直到全部完成

# 节点执行规范
- 严格按照 WORKFLOW.md 中的流程顺序执行
- 渐进式加载：执行到某个节点时才读取该节点的详细定义
- 节点失败后最多重试2次，错误记录到 PROGRESS.md 的"错误与重试记录"表
- 每个节点完成后必须更新 PROGRESS.md 和 ARTIFACTS.md
- **产物文件必须归档到当前实例目录下：`instance/{id}/artifacts/{节点名}/`。禁止将产物写到项目根目录或其他位置。**
