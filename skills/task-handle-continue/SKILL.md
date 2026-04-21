---
name: task-handle-continue
description: 继续执行已有工作流实例。参数为实例ID。示例：/task-handle-continue 20260422-014352。如果不提供实例ID，将自动查找最近的中断实例。
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

# 实例ID
$ARGUMENTS

# 执行步骤

## 步骤 1: 定位实例

**如果提供了实例ID**：
实例目录为 `.claude/workflows/{工作流名}/instance/{实例ID}/`

**如果未提供实例ID**：
使用 find 查找最近的实例：
```bash
find .claude/workflows -path '*/instance/*/PROGRESS.md' -type f 2>/dev/null | head -1
```
提取实例目录路径。

## 步骤 2: 读取进度恢复上下文
读取 `instance/{实例ID}/PROGRESS.md`，获取：
- **工作流名称**
- **当前节点**（如果为"未开始"或"(刚完成 xxx)"，则确定下一个节点）
- **状态**（in_progress / pending / completed）
- **已完成的节点列表**（从"节点进度"表中筛选 status=complete 的行）
- **执行日志**
- **错误记录**

同时读取同目录下的 `ARTIFACTS.md` 了解已有产物。

## 步骤 3: 读取工作流定义
读取 `.claude/workflows/{工作流名}/WORKFLOW.md`，确认：
- 整体流程结构
- 当前节点在流程中的位置
- 剩余未执行的节点

## 步骤 4: 确定恢复点
根据 PROGRESS.md 中的当前节点和已完成节点列表，确定：
1. 如果状态为 `completed` → 告知用户所有节点已完成，展示 ARTIFACTS.md 中的交付物
2. 如果当前节点为"未开始" → 从第一个业务节点开始执行
3. 如果当前节点为"(刚完成 xxx)" → 找到流程中的下一个节点开始执行
4. 如果当前节点为具体节点名 → 继续执行该节点

## 步骤 5: 继续执行
1. 更新 PROGRESS.md：
   - "当前状态"中当前节点改为目标节点
   - "状态"改为 in_progress
   - "执行日志"追加"恢复执行"记录
   - "节点进度"表中添加/更新目标节点（状态 in_progress）
2. 读取当前节点的定义文件
3. 执行节点任务
4. 完成后更新 PROGRESS.md：
   - "节点进度"表中该节点状态改为 complete，填写完成时间
   - "当前状态"中当前节点改为"(刚完成 xxx)"
   - "执行日志"追加"完成节点"记录
5. 如有产物，更新 ARTIFACTS.md
6. 继续下一个节点，循环直到全部完成

# 恢复执行规范
- 必须先读取 PROGRESS.md 理解上下文，再读取 WORKFLOW.md 理解流程
- 严格按照流程顺序执行，禁止跳过节点
- 如果节点已部分执行但未完成，重新执行该节点
- 节点失败后最多重试2次
- 持续更新 PROGRESS.md 和 ARTIFACTS.md
- **产物文件必须归档到当前实例目录下：`instance/{id}/artifacts/{节点名}/`。禁止将产物写到项目根目录或其他位置。**
