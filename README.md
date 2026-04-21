# Workflow with Files

English | [中文](README.zh.md)

A Claude Code workflow system that organizes and tracks progress on complex tasks using file-based planning. Inspired by Manus-style planning.

## Overview

This project provides a structured approach to managing multi-step tasks through:

- **File-based planning**: Tasks are broken down into nodes and tracked via Markdown files
- **Progress tracking**: Real-time progress monitoring through `PROGRESS.md`
- **Artifact management**: Centralized artifact storage per workflow instance
- **Hook integration**: Automatic context injection during AI execution

## Project Structure

```
.claude/
├── nodes/                    # Knowledge nodes for workflow steps
├── skills/                   # Claude Code skills
│   ├── task-handle/         # Workflow supervision system
│   ├── task-handle-continue/# Instance continuation skill
│   └── task-handle-instance/# Instance creation skill
├── workflows/               # Workflow definitions
│   └── {workflow-name}/
│       ├── meta-data/       # Workflow metadata
│       └── instance/        # Active workflow instances
│           └── {timestamp-id}/
│               ├── PROGRESS.md    # State source of truth
│               ├── ARTIFACTS.md   # Artifact manifest + conclusions
│               └── artifacts/     # Output files organized by node
├── settings.local.json      # Local Claude Code settings
└── .gitignore               # Git ignore rules
```

## Skills

| Skill | Description |
|-------|-------------|
| `task-handle` | Workflow supervision system with hooks that inject progress context |
| `task-handle-instance` | Creates new workflow instances from user requirements |
| `task-handle-continue` | Resumes existing workflow instances |

## Quick Start

1. Activate the skills in your Claude Code environment
2. Start a workflow with `/task-handle-instance <requirement>`
3. Track progress through the generated `PROGRESS.md`
4. Resume later with `/task-handle-continue [instance-id]`

## License

[MIT](LICENSE)
