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
echo "▶ Step 3: Global configs..."
echo "  ℹ CLAUDE.md, settings.json, statusline.sh → managed by claude-code-config repo"
echo "    Install: cd ~/Desktop/workspace/claude-code-config && ./install.sh"

# .prettierrc 由 cursor_vscode_config 仓库管理，不在此处安装

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

# ── Step 5: Memory iCloud 同步 ──
echo ""
echo "▶ Step 5: Memory iCloud sync..."

ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
MEMORY_DIR_NAME="$(echo "$HOME" | tr '/' '-')"
MEMORY_PATH="$HOME/.claude/projects/$MEMORY_DIR_NAME/memory"
ICLOUD_MEMORY="$ICLOUD_DIR/claude-memory"

if [[ ! -d "$ICLOUD_DIR" ]]; then
  echo "  ⚠ iCloud Drive not found, skipping"
  echo "    (sign in to iCloud and enable Desktop & Documents Folders)"
elif [[ -L "$MEMORY_PATH" ]]; then
  echo "  ✓ Memory already synced via iCloud (symlink exists)"
else
  mkdir -p "$ICLOUD_MEMORY"
  if [[ -d "$MEMORY_PATH" ]]; then
    echo "  ↻ Migrating existing memory to iCloud..."
    cp -r "$MEMORY_PATH/." "$ICLOUD_MEMORY/"
    rm -rf "$MEMORY_PATH"
  fi
  mkdir -p "$(dirname "$MEMORY_PATH")"
  ln -s "$ICLOUD_MEMORY" "$MEMORY_PATH"
  echo "  ✓ Memory → ~/iCloud Drive/claude-memory (symlinked)"
fi

# ── Done ──
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  ✅ Done! Restart Claude Code to load all skills & plugins."
echo ""
echo "  Skills: $SKILL_LIST"
echo "  Plugins: superpowers, frontend-design, skill-creator, planning-with-files"
echo "  Configs: → claude-code-config repo"
echo "  Memory:  iCloud Drive/claude-memory"
echo "══════════════════════════════════════════════════════════"
