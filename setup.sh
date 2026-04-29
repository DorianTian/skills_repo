#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════
# claude-skills — Claude Code Skills Installer
# Usage:
#   claude-skills                 Interactive mode
#   claude-skills --all           Install all skills + external plugins
#   claude-skills --skills        Install skills only
#   claude-skills --external      Install external plugins only (gstack)
#   claude-skills --link          Register CLI command
#   Plugins are managed by claude-config (~/dev-env/claude_setting)
# ══════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
AGENTS_DIR="$HOME/.claude/agents"

# ── Parse flags ──
INSTALL_SKILLS=false
INSTALL_EXTERNAL=false
LINK=false
INTERACTIVE=false

if [[ $# -eq 0 ]]; then
  INTERACTIVE=true
else
  for arg in "$@"; do
    case "$arg" in
      --all) INSTALL_SKILLS=true; INSTALL_EXTERNAL=true ;;
      --skills) INSTALL_SKILLS=true ;;
      --external) INSTALL_EXTERNAL=true ;;
      --link) LINK=true ;;
      --help|-h)
        echo "Usage: claude-skills [options]"
        echo ""
        echo "Options:"
        echo "  (none)       Interactive mode"
        echo "  --all        Install all skills + external plugins"
        echo "  --skills     Install skills only"
        echo "  --external   Install external plugins only (gstack)"
        echo "  --link       Register CLI command"
        echo "  --help       Show this help"
        echo ""
        echo "  Plugins are managed by claude-config (~/dev-env/claude_setting)"
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
  echo "    e) External plugins (gstack)"
  echo "    f) Full setup (all skills + external + CLI)"
  echo "    l) Register CLI command (claude-skills)"
  echo ""
  printf "  Enter choices (e.g. 1 3 p, or f for full): "
  read -r choices

  SELECTED_SKILLS=()
  for choice in $choices; do
    case "$choice" in
      a) INSTALL_SKILLS=true ;;
      e) INSTALL_EXTERNAL=true ;;
      l) LINK=true ;;
      f) INSTALL_SKILLS=true; INSTALL_EXTERNAL=true; LINK=true ;;
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
echo "  claude-skills — Installing Skills"
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

# ── Install subagent definitions (paired with expert-team / ai-mentors) ──
NEED_EXPERT_AGENTS=false
NEED_MENTOR_AGENTS=false

if [[ "$INSTALL_SKILLS" == "true" ]]; then
  NEED_EXPERT_AGENTS=true
  NEED_MENTOR_AGENTS=true
elif [[ ${#SELECTED_SKILLS[@]:-0} -gt 0 ]]; then
  for s in "${SELECTED_SKILLS[@]}"; do
    case "$s" in
      expert-team) NEED_EXPERT_AGENTS=true ;;
      ai-mentors) NEED_MENTOR_AGENTS=true ;;
    esac
  done
fi

if { [[ "$NEED_EXPERT_AGENTS" == "true" ]] || [[ "$NEED_MENTOR_AGENTS" == "true" ]]; } && [[ -d "$SCRIPT_DIR/agents" ]]; then
  echo ""
  echo "▶ Installing subagent definitions..."
  mkdir -p "$AGENTS_DIR"
  AGENT_COUNT=0
  for agent_file in "$SCRIPT_DIR"/agents/*.md; do
    [[ ! -f "$agent_file" ]] && continue
    agent_name="$(basename "$agent_file")"
    case "$agent_name" in
      expert-*) [[ "$NEED_EXPERT_AGENTS" != "true" ]] && continue ;;
      mentor-*) [[ "$NEED_MENTOR_AGENTS" != "true" ]] && continue ;;
    esac
    cp "$agent_file" "$AGENTS_DIR/$agent_name"
    AGENT_COUNT=$((AGENT_COUNT + 1))
  done
  echo "  ✓ Subagents installed: $AGENT_COUNT files → $AGENTS_DIR"
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

# ── External plugins (git-based) ──
GSTACK_REPO="https://github.com/garrytan/gstack.git"
GSTACK_DIR="$SKILLS_DIR/gstack"

if [[ "$INSTALL_EXTERNAL" == "true" ]]; then
  echo ""
  echo "▶ Installing external plugins..."

  # gstack
  if [[ -d "$GSTACK_DIR/.git" ]]; then
    echo "  ↻ gstack (updating)"
    git -C "$GSTACK_DIR" pull --ff-only 2>/dev/null || echo "  ⚠ gstack pull failed, running setup on existing version"
  else
    echo "  + gstack (cloning)"
    [[ -d "$GSTACK_DIR" ]] && rm -rf "$GSTACK_DIR"
    git clone --single-branch --depth 1 "$GSTACK_REPO" "$GSTACK_DIR"
  fi

  if command -v bun &>/dev/null; then
    echo "  ▶ Running gstack setup (--prefix)..."
    cd "$GSTACK_DIR" && ./setup --prefix -q 2>&1 | tail -3
    cd "$SCRIPT_DIR"
    echo "  ✓ gstack installed (prefix mode)"
  else
    echo "  ⚠ bun not found — gstack requires bun. Install: curl -fsSL https://bun.sh/install | bash"
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
echo "  ℹ Plugins & global configs (settings.json, statusline, CLAUDE.md):"
echo "    → claude-config (cd ~/dev-env/claude_setting && ./install.sh)"
echo "══════════════════════════════════════════════════════════"
