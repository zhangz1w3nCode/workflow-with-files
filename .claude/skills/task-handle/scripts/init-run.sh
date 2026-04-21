#!/bin/bash
# init-run.sh — 初始化一个新的工作流实例
# 用法: ./init-run.sh <workflow-name> [task-summary]

set -e

WORKFLOW_NAME="${1:-标准流水线}"
TASK_SUMMARY="${2:-未命名任务}"
INSTANCE_ID=$(date +%Y%m%d-%H%M%S)
TIMESTAMP=$(date -Iseconds)

WORKFLOW_DIR=".claude/workflows/$WORKFLOW_NAME"
INSTANCE_DIR="$WORKFLOW_DIR/instance/$INSTANCE_ID"

if [ ! -d "$WORKFLOW_DIR" ]; then
    echo "错误: 工作流 '$WORKFLOW_NAME' 不存在于 $WORKFLOW_DIR"
    exit 1
fi

mkdir -p "$INSTANCE_DIR"

# 创建工作流定义路径引用
WORKFLOW_DEF="$WORKFLOW_DIR/WORKFLOW.md"
if [ ! -f "$WORKFLOW_DEF" ]; then
    echo "警告: 工作流定义文件不存在: $WORKFLOW_DEF"
fi

# 创建 PROGRESS.md
PROGRESS_FILE="$INSTANCE_DIR/PROGRESS.md"
cat > "$PROGRESS_FILE" << EOF
# 工作流进度: $WORKFLOW_NAME

## 当前状态
- **实例ID**: $INSTANCE_ID
- **工作流**: $WORKFLOW_NAME
- **任务**: $TASK_SUMMARY
- **当前节点**: 未开始
- **运行开始**: $TIMESTAMP
- **状态**: in_progress

## 节点进度

| 序号 | 节点名称 | 状态 | 开始时间 | 完成时间 | 重试次数 |
|------|---------|------|---------|---------|---------|

## 执行日志
- [$TIMESTAMP] 工作流实例 $INSTANCE_ID 初始化
- [$TIMESTAMP] 任务: $TASK_SUMMARY

## 错误与重试记录
| 节点 | 错误描述 | 尝试次数 | 解决方案 |
|------|---------|---------|---------|

## 5-问重启测试
| 问题 | 答案 |
|------|------|
| 我在哪个工作流? | $WORKFLOW_NAME |
| 当前节点是什么? | 未开始 |
| 任务目标是什么? | $TASK_SUMMARY |
| 已完成的节点? | 无 |
| 产物在哪里? | 见 ARTIFACTS.md |
EOF

# 创建 ARTIFACTS.md
ARTIFACTS_FILE="$INSTANCE_DIR/ARTIFACTS.md"
cat > "$ARTIFACTS_FILE" << EOF
# 工作流产物: $WORKFLOW_NAME

## 运行信息
- **实例ID**: $INSTANCE_ID
- **工作流**: $WORKFLOW_NAME
- **任务摘要**: $TASK_SUMMARY
- **运行时间**: $TIMESTAMP

## 节点产物汇总
<!-- 每个节点完成后，在此追加产物和结论 -->

## 最终交付物
<!-- 工作流全部完成后，在此汇总所有需要交付给用户的产物 -->
- [ ] 待补充

## 产物索引
<!-- 按类型快速索引 -->

### 代码文件
<!-- 所有 .py, .js, .ts 等 -->

### 文档
<!-- 所有 .md, .txt 等 -->

### 配置文件
<!-- 所有 .json, .yaml, .toml 等 -->
EOF

echo "工作流实例已初始化: $INSTANCE_DIR"
echo "实例ID: $INSTANCE_ID"
echo "工作流: $WORKFLOW_NAME"
echo "任务: $TASK_SUMMARY"
echo ""
echo "文件:"
echo "  - PROGRESS.md: $PROGRESS_FILE"
echo "  - ARTIFACTS.md: $ARTIFACTS_FILE"
