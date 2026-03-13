# Claude Code Skills & Plugins

> 一键同步 Claude Code 的 skills 和 plugins 到任意机器。

## Quick Start

```bash
git clone git@github.com:DorianTian/skills_repo.git
cd skills_repo
./setup.sh
```

## 包含内容

### Skills (4)

| Skill | 用途 |
|-------|------|
| `best-minds` | 模拟世界顶级专家视角回答问题 |
| `expert-team` | 自动匹配专家角色（前端/AI/数据/全栈/DevOps 等） |
| `find-skills` | 发现和安装新的 skills |
| `notebooklm` | 从 Claude Code 直接查询 Google NotebookLM |

### Plugins (3)

| Plugin | 来源 | 用途 |
|--------|------|------|
| `superpowers` | 官方 | TDD、brainstorming、plan、debug 等工作流 |
| `frontend-design` | 官方 | 高质量前端 UI 生成 |
| `skill-creator` | 官方 | 创建和优化 skills |

### Global Configs

| 文件 | 用途 |
|------|------|
| `claude-config/CLAUDE.md` | 全局指令：交互规则、代码规范、深度文档规范 |
| `.prettierrc` | 全局 Prettier 配置（semi, singleQuote, 120 cols） |

## setup.sh 做了什么

1. 复制 `skills/` 下所有 skill 到 `~/.claude/skills/`
2. 在 `~/.claude/settings.json` 中启用 3 个 plugins
3. 复制 `CLAUDE.md` 到 `~/.claude/`、`.prettierrc` 到 `~/`
4. 为 notebooklm 安装 Python 依赖（`.venv`）
