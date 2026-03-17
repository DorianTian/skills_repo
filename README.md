# Claude Code Skills & Plugins

> 一键同步 Claude Code 的 skills、plugins、全局配置和 memory 到任意机器。

## Quick Start

```bash
git clone git@github.com:DorianTian/skills_repo.git
cd skills_repo
./setup.sh
```

## 包含内容

### Skills (8)

| Skill | 用途 |
|-------|------|
| `ai-mentors` | AI/ML 学习问答，多专家视角（Karpathy 等） |
| `best-minds` | 模拟世界顶级专家视角回答问题 |
| `deep-doc` | 生成深度技术分析文档（学术原理 + 工程实践） |
| `design-guide` | 设计模式选择指南（GoF / CQRS / Event Sourcing / 前端模式 / 反模式） |
| `expert-team` | 自动匹配专家角色（前端/AI/数据/全栈/DevOps 等） |
| `find-skills` | 发现和安装新的 skills |
| `notebooklm` | 从 Claude Code 直接查询 Google NotebookLM |
| `setup-project` | 项目脚手架（Next.js 16 / Koa.js / Full-stack） |

### Plugins (4)

| Plugin | 来源 | 用途 |
|--------|------|------|
| `superpowers` | 官方 | TDD、brainstorming、plan、debug 等工作流 |
| `frontend-design` | 官方 | 高质量前端 UI 生成 |
| `skill-creator` | 官方 | 创建和优化 skills |
| `planning-with-files` | 社区 | Manus 风格文件化规划（task_plan.md / findings.md / progress.md） |

### Global Configs

| 文件 | 用途 |
|------|------|
| `claude-config/CLAUDE.md` | 全局指令：交互规则、代码规范、AI 驱动开发模式 |
| `claude-config/settings.json` | 插件启用配置 + marketplace 源 |

> `.prettierrc` 由 [cursor_vscode_config](https://github.com/DorianTian/cursor_vscode_config) 管理，不在此处安装。

## setup.sh 做了什么

1. 复制 `skills/` 下所有 skill 到 `~/.claude/skills/`
2. 在 `~/.claude/settings.json` 中启用 4 个 plugins（含 marketplace 配置）
3. 复制 `CLAUDE.md` 到 `~/.claude/`
4. 为 notebooklm 安装 Python 依赖（`.venv`）
5. 将 Claude memory 迁移至 iCloud Drive 并建立软链接，实现跨机自动同步

## 设计理念

- **CLAUDE.md 管 invariants**：只放永远不可违反的规则（分层架构、SOLID、no-any 等）
- **Skills 管 contextual decisions**：设计模式选择（`/design-guide`）、项目脚手架（`/setup-project`）等按需调用
- **Memory 走 iCloud**：跨机一致性，自动同步，无需手动维护
- 避免规则过载导致 LLM attention dilution 和 rule conflicts
