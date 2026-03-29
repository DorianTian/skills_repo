#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════
# claude-skills — Claude Code Skills & Plugins Installer
# Usage:
#   claude-skills                 Interactive mode
#   claude-skills --all           Install all skills + plugins
#   claude-skills --skills        Install skills only
#   claude-skills --plugins       Install plugins only
#   claude-skills --link          Register CLI command
#   Flags can be combined: claude-skills --skills --plugins
# ══════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
SETTINGS_FILE="$HOME/.claude/settings.json"

# ── Parse flags ──
INSTALL_SKILLS=false
INSTALL_PLUGINS=false
LINK=false
INTERACTIVE=false

if [[ $# -eq 0 ]]; then
  INTERACTIVE=true
else
  for arg in "$@"; do
    case "$arg" in
      --all) INSTALL_SKILLS=true; INSTALL_PLUGINS=true ;;
      --skills) INSTALL_SKILLS=true ;;
      --plugins) INSTALL_PLUGINS=true ;;
      --link) LINK=true ;;
      --help|-h)
        echo "Usage: claude-skills [options]"
        echo ""
        echo "Options:"
        echo "  (none)       Interactive mode"
        echo "  --all        Install all skills + plugins"
        echo "  --skills     Install skills only"
        echo "  --plugins    Install plugins only"
        echo "  --link       Register CLI command"
        echo "  --help       Show this help"
        exit 0
        ;;
    esac
  done
fi

# ── List available skills ──
AVAILABLE_SKILLS=()
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
  [[ -d "$skill_dir" ]] && AVAILABLE_SKILLS+=("$(basename "$skill_dir")")
done

# ── Interactive menu ──
if [[ "$INTERACTIVE" == "true" ]]; then
  echo "══════════════════════════════════════════════════════════"
  echo "  claude-skills — Skills & Plugins Installer"
  echo "══════════════════════════════════════════════════════════"
  echo ""
  echo "  Available skills:"
  i=1
  for skill in "${AVAILABLE_SKILLS[@]}"; do
    printf "    %2d) %s\n" "$i" "$skill"
    ((i++))
  done
  echo ""
  echo "  Other:"
  echo "    a) All skills"
  echo "    p) Plugins (superpowers, frontend-design, skill-creator, planning-with-files, LSPs, telegram, code-review, feature-dev, commit-commands)"
  echo "    f) Full setup (all skills + plugins + CLI)"
  echo "    l) Register CLI command (claude-skills)"
  echo ""
  printf "  Enter choices (e.g. 1 3 p, or f for full): "
  read -r choices

  SELECTED_SKILLS=()
  for choice in $choices; do
    case "$choice" in
      a) INSTALL_SKILLS=true ;;
      p) INSTALL_PLUGINS=true ;;
      l) LINK=true ;;
      f) INSTALL_SKILLS=true; INSTALL_PLUGINS=true; LINK=true ;;
      *[0-9]*)
        idx=$((choice - 1))
        if [[ $idx -ge 0 && $idx -lt ${#AVAILABLE_SKILLS[@]} ]]; then
          SELECTED_SKILLS+=("${AVAILABLE_SKILLS[$idx]}")
        else
          echo "  ⚠ Invalid number: $choice"
        fi
        ;;
      *) echo "  ⚠ Unknown option: $choice" ;;
    esac
  done
  echo ""
fi

echo "══════════════════════════════════════════════════════════"
echo "  claude-skills — Installing"
echo "══════════════════════════════════════════════════════════"

# ── Install skills ──
if [[ "$INSTALL_SKILLS" == "true" ]]; then
  echo ""
  echo "▶ Installing all skills..."
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
elif [[ ${#SELECTED_SKILLS[@]:-0} -gt 0 ]]; then
  echo ""
  echo "▶ Installing selected skills..."
  SKILL_LIST=""
  for skill_name in "${SELECTED_SKILLS[@]}"; do
    skill_dir="$SCRIPT_DIR/skills/$skill_name"
    target="$SKILLS_DIR/$skill_name"
    if [[ ! -d "$skill_dir" ]]; then
      echo "  ✗ $skill_name not found"
      continue
    fi
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
fi

# ── Install plugins ──
if [[ "$INSTALL_PLUGINS" == "true" ]]; then
  echo ""
  echo "▶ Installing plugins..."
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  [[ -f "$SETTINGS_FILE" ]] || echo '{}' > "$SETTINGS_FILE"

  python3 - "$SETTINGS_FILE" <<'PYEOF'
import json, sys

settings_path = sys.argv[1]
with open(settings_path, "r") as f:
    settings = json.load(f)

required_plugins = {
    "superpowers@claude-plugins-official": True,
    "frontend-design@claude-plugins-official": True,
    "planning-with-files@planning-with-files": True,
    "skill-creator@claude-plugins-official": True,
    "typescript-lsp@claude-plugins-official": True,
    "gopls-lsp@claude-plugins-official": True,
    "pyright-lsp@claude-plugins-official": True,
    "telegram@claude-plugins-official": True,
    "code-review@claude-plugins-official": True,
    "feature-dev@claude-plugins-official": True,
    "commit-commands@claude-plugins-official": True,
}

required_marketplaces = {
    "planning-with-files": {
        "source": {
            "source": "github",
            "repo": "OthmanAdi/planning-with-files"
        }
    }
}

enabled = settings.get("enabledPlugins", {})
enabled.update(required_plugins)
settings["enabledPlugins"] = enabled

marketplaces = settings.get("extraKnownMarketplaces", {})
marketplaces.update(required_marketplaces)
settings["extraKnownMarketplaces"] = marketplaces

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

print("  ✓ Plugins enabled: superpowers, frontend-design, skill-creator, planning-with-files, typescript-lsp, gopls-lsp, pyright-lsp, telegram, code-review, feature-dev, commit-commands")
PYEOF
fi

# ── NotebookLM dependencies ──
if [[ "$INSTALL_SKILLS" == "true" ]] || [[ " ${SELECTED_SKILLS[*]:-} " == *" notebooklm "* ]]; then
  if [[ -f "$SKILLS_DIR/notebooklm/requirements.txt" ]]; then
    echo ""
    echo "▶ NotebookLM dependencies..."
    if command -v python3 &>/dev/null; then
      cd "$SKILLS_DIR/notebooklm"
      python3 -m venv .venv 2>/dev/null || true
      .venv/bin/pip install -r requirements.txt -q 2>/dev/null && \
        echo "  ✓ Python dependencies installed" || \
        echo "  ⚠ Failed — run manually: cd $SKILLS_DIR/notebooklm && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt"
      cd "$SCRIPT_DIR"
    else
      echo "  ⚠ python3 not found, skip notebooklm deps"
    fi
  fi
fi

# ── Register CLI command ──
if [[ "$LINK" == "true" ]]; then
  echo ""
  echo "▶ Registering CLI command..."
  mkdir -p "$HOME/.local/bin"
  ln -sf "$SCRIPT_DIR/setup.sh" "$HOME/.local/bin/claude-skills"
  echo "  ✓ claude-skills → $SCRIPT_DIR/setup.sh"
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "  ⚠ ~/.local/bin is not in PATH. Add to ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
fi

# ── Summary ──
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  ✅ Done! Restart Claude Code to load changes."
echo ""
echo "  ℹ Global configs (settings.json, statusline, CLAUDE.md):"
echo "    → claude-config (or cd ~/dev-env/claude_setting && ./install.sh)"
echo "══════════════════════════════════════════════════════════"
