#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════
# Claude Code Skills & Plugins 一键配置
# 用法: ./setup.sh
# ══════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "══════════════════════════════════════════════════════════"
echo "  Claude Code Skills & Plugins Setup"
echo "══════════════════════════════════════════════════════════"

# ── Step 1: 安装 Skills ──
echo ""
echo "▶ Step 1: Installing skills..."

SKILL_LIST=""
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  target="$SKILLS_DIR/$skill_name"
  if [[ -d "$target" ]]; then
    echo "  ↻ $skill_name (updating)"
    rm -rf "$target"
  else
    echo "  + $skill_name"
  fi
  cp -r "$skill_dir" "$target"
  SKILL_LIST="$SKILL_LIST $skill_name"
done
echo "  ✓ Skills installed:$SKILL_LIST"

# ── Step 2: 安装 Plugins ──
echo ""
echo "▶ Step 2: Installing plugins..."

# 确保 settings.json 存在
mkdir -p "$(dirname "$SETTINGS_FILE")"
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# 用 python3 合并 plugin 配置（保留已有设置）
python3 - "$SETTINGS_FILE" <<'PYEOF'
import json, sys

settings_path = sys.argv[1]
with open(settings_path, "r") as f:
    settings = json.load(f)

# 需要启用的 plugins
required_plugins = {
    "superpowers@claude-plugins-official": True,
    "frontend-design@claude-plugins-official": True,
    "planning-with-files@planning-with-files": True,
    "skill-creator@claude-plugins-official": True,
}

# 需要的 marketplace 配置
required_marketplaces = {
    "planning-with-files": {
        "source": {
            "source": "github",
            "repo": "OthmanAdi/planning-with-files"
        }
    }
}

# 合并 enabledPlugins
enabled = settings.get("enabledPlugins", {})
enabled.update(required_plugins)
settings["enabledPlugins"] = enabled

# 合并 extraKnownMarketplaces
marketplaces = settings.get("extraKnownMarketplaces", {})
marketplaces.update(required_marketplaces)
settings["extraKnownMarketplaces"] = marketplaces

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

print("  ✓ Plugins enabled: superpowers, frontend-design, skill-creator, planning-with-files")
PYEOF

# ── Step 3: 全局配置文件 ──
echo ""
echo "▶ Step 3: Installing global configs..."

# CLAUDE.md（全局指令：代码规范、交互规则、系统设计规范、深度文档规范）
if [[ -f "$SCRIPT_DIR/claude-config/CLAUDE.md" ]]; then
  if [[ -f "$HOME/.claude/CLAUDE.md" ]]; then
    cp "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.bak"
    echo "  ↻ CLAUDE.md (backed up → CLAUDE.md.bak)"
  fi
  cp "$SCRIPT_DIR/claude-config/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  echo "  ✓ CLAUDE.md"
fi

# .prettierrc（全局 Prettier 配置）
if [[ -f "$SCRIPT_DIR/.prettierrc" ]]; then
  if [[ -f "$HOME/.prettierrc" ]]; then
    cp "$HOME/.prettierrc" "$HOME/.prettierrc.bak"
  fi
  cp "$SCRIPT_DIR/.prettierrc" "$HOME/.prettierrc"
  echo "  ✓ .prettierrc"
fi

# ── Step 4: notebooklm 依赖 ──
echo ""
echo "▶ Step 4: NotebookLM dependencies..."
if [[ -f "$SKILLS_DIR/notebooklm/requirements.txt" ]]; then
  if command -v python3 &>/dev/null; then
    cd "$SKILLS_DIR/notebooklm"
    python3 -m venv .venv 2>/dev/null || true
    .venv/bin/pip install -r requirements.txt -q 2>/dev/null && \
      echo "  ✓ Python dependencies installed" || \
      echo "  ⚠ Failed to install dependencies, run manually: cd $SKILLS_DIR/notebooklm && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt"
    cd "$SCRIPT_DIR"
  else
    echo "  ⚠ python3 not found, skip notebooklm deps"
  fi
fi

# ── Done ──
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  ✅ Done! Restart Claude Code to load all skills & plugins."
echo ""
echo "  Skills: $SKILL_LIST"
echo "  Plugins: superpowers, frontend-design, skill-creator, planning-with-files"
echo "  Configs: CLAUDE.md, .prettierrc"
echo "══════════════════════════════════════════════════════════"
