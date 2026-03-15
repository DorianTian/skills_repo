---
name: setup-vscode-neovim
description: Use when setting up a new Cursor or VSCode environment - configures complete editor appearance (theme, fonts, UX) and vscode-neovim with unified keybindings across Neovim, Cursor, and VSCode. Trigger words - setup cursor, configure vim, cursor config, vscode neovim, new machine setup
---

# Cursor + VSCode-Neovim Complete Setup

One-command setup for a production-grade Cursor environment: beautiful appearance + unified Vim keybindings across Neovim / Cursor / VSCode.

## Architecture

```
Cursor/VSCode settings.json    →  外观 + 行为 + 格式化 + 扩展配置
~/.config/nvim/lua/config/
├── lazy.lua                   →  VSCode 模式只加载 surround，Neovim 加载全部
├── keymaps.lua                →  vim.g.vscode 分支：70+ 统一快捷键
└── options.lua                →  三端共享选项
```

## Step 1: Install Fonts

Must install before configuring. Priority order:

1. **Maple Mono** (primary) — best ligatures + cursive italic
2. **Victor Mono** (fallback) — elegant italic
3. **JetBrains Mono** (fallback) — solid default

```bash
# Maple Mono
brew install --cask font-maple-mono
# Victor Mono
brew install --cask font-victor-mono
# JetBrains Mono
brew install --cask font-jetbrains-mono
```

## Step 2: Install Extensions

```bash
# Theme + Icons
cursor --install-extension Catppuccin.catppuccin-vsc
cursor --install-extension Catppuccin.catppuccin-vsc-icons
cursor --install-extension antfu.icons-carbon

# Neovim
cursor --install-extension asvetliakov.vscode-neovim

# Git
cursor --install-extension eamodio.gitlens

# Error Lens (inline diagnostics)
cursor --install-extension usernamehw.errorlens
```

If `cursor` CLI not available, install via Extensions panel.

## Step 3: Write Cursor settings.json

Path:
- **macOS Cursor**: `~/Library/Application Support/Cursor/User/settings.json`
- **macOS VSCode**: `~/Library/Application Support/Code/User/settings.json`
- **Linux Cursor**: `~/.config/Cursor/User/settings.json`
- **Linux VSCode**: `~/.config/Code/User/settings.json`

Write the following complete config (overwrite existing):

```json
{
  // ══ 字体 ══
  "editor.fontFamily": "'Maple Mono', 'Victor Mono', 'JetBrains Mono', 'Fira Code', Menlo, monospace",
  "editor.fontSize": 15,
  "editor.fontWeight": "400",
  "editor.fontLigatures": "'calt', 'liga', 'ss01', 'ss02'",
  "editor.fontVariations": true,
  "terminal.integrated.fontFamily": "'Maple Mono', 'Victor Mono', 'JetBrains Mono'",
  "terminal.integrated.fontSize": 14,
  "terminal.integrated.fontWeightBold": "bold",
  "terminal.integrated.fontLigatures.enabled": true,
  "debug.console.fontFamily": "'Victor Mono'",
  "debug.console.fontSize": 14,
  "scm.inputFontFamily": "'Victor Mono'",
  "scm.inputFontSize": 14,
  "notebook.markup.fontFamily": "'Victor Mono'",
  "notebook.markup.fontSize": 14,
  "notebook.output.fontFamily": "'Victor Mono'",
  "notebook.output.fontSize": 14,
  "editor.inlineSuggest.fontFamily": "'Victor Mono'",
  "editor.suggestFontSize": 14,
  "errorLens.fontFamily": "'Victor Mono'",
  "errorLens.fontSize": "13",

  // ══ 主题 & 外观 ══
  "workbench.colorTheme": "Catppuccin Mocha",
  "workbench.iconTheme": "catppuccin-mocha",
  "workbench.productIconTheme": "icons-carbon",
  "workbench.sideBar.location": "right",
  "window.commandCenter": true,
  "editor.semanticHighlighting.enabled": true,
  "editor.tokenColorCustomizations": {
    "[Catppuccin Mocha]": {
      "textMateRules": [
        {
          "scope": ["comment", "keyword", "storage.modifier", "variable.language.this", "entity.other.attribute-name"],
          "settings": { "fontStyle": "italic" }
        }
      ]
    }
  },

  // ══ 编辑器体验 ══
  "editor.tabSize": 2,
  "editor.lineNumbers": "relative",
  "editor.cursorSurroundingLines": 8,
  "editor.cursorBlinking": "smooth",
  "editor.cursorSmoothCaretAnimation": "on",
  "editor.smoothScrolling": true,
  "editor.mouseWheelScrollSensitivity": 2,
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": "active",
  "editor.guides.indentation": true,
  "editor.guides.highlightActiveIndentation": true,
  "editor.minimap.enabled": true,
  "editor.minimap.renderCharacters": false,
  "editor.minimap.maxColumn": 80,
  "editor.minimap.autohide": true,
  "editor.stickyScroll.enabled": true,
  "editor.stickyScroll.maxLineCount": 3,
  "editor.formatOnSave": true,
  "editor.formatOnPaste": false,
  "editor.linkedEditing": true,
  "editor.renderWhitespace": "boundary",
  "editor.wordWrap": "off",
  "editor.rulers": [120],
  "editor.inlayHints.enabled": "onUnlessPressed",
  "editor.inlayHints.fontSize": 12,
  "diffEditor.ignoreTrimWhitespace": false,

  // ══ 终端 ══
  "terminal.integrated.smoothScrolling": true,
  "terminal.integrated.cursorBlinking": true,
  "terminal.integrated.cursorStyle": "line",

  // ══ Workbench 行为 ══
  "explorer.confirmDelete": false,
  "explorer.confirmDragAndDrop": false,
  "explorer.compactFolders": false,
  "workbench.editor.tabSizing": "shrink",
  "workbench.editor.enablePreview": true,
  "workbench.startupEditor": "none",
  "workbench.list.smoothScrolling": true,
  "workbench.tree.indent": 16,
  "workbench.settings.applyToAllProfiles": [],

  // ══ 语言 Formatter ══
  "[vue]": { "editor.defaultFormatter": "Vue.volar" },
  "[typescript]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[typescriptreact]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[javascript]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[json]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[jsonc]": { "editor.defaultFormatter": "vscode.json-language-features" },
  "[html]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[css]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[scss]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[less]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[yaml]": { "editor.defaultFormatter": "redhat.vscode-yaml" },
  "[sql]": { "editor.defaultFormatter": "cweijan.vscode-database-client2" },
  "[go]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "golang.go",
    "editor.codeActionsOnSave": { "source.organizeImports": "explicit" }
  },

  // ══ 语言 & 工具 ══
  "go.formatTool": "goimports",
  "go.toolsManagement.autoUpdate": true,
  "go.alternateTools": { "dlv": "/opt/homebrew/bin/dlv" },
  "go.lintTool": "golangci-lint",
  "go.lintOnSave": "workspace",
  "javascript.updateImportsOnFileMove.enabled": "always",
  "typescript.updateImportsOnFileMove.enabled": "always",
  "json.schemas": [],

  // ══ Git ══
  "git.enableSmartCommit": true,
  "git.autofetch": true,
  "git.openRepositoryInParentFolders": "never",
  "gitlens.graph.layout": "editor",
  "gitlens.codeLens.enabled": false,

  // ══ 扩展 ══
  "database-client.autoSync": true,
  "redhat.telemetry.enabled": true,
  "console-ninja.featureSet": "Community",
  "console-ninja.fontSize": 14,
  "makefile.configureOnOpen": true,
  "security.promptForLocalFileProtocolHandling": false,
  "keyboard.dispatch": "keyCode",

  // ══ Claude Code ══
  "claudeCode.useTerminal": true,
  "claudeCode.environmentVariables": [],

  // ══ VSCode-Neovim ══
  "vscode-neovim.neovimExecutablePaths.darwin": "/opt/homebrew/bin/nvim",
  "extensions.experimental.affinity": {
    "asvetliakov.vscode-neovim": 1
  }
}
```

**Adjust `neovimExecutablePaths` based on `which nvim` output.**

## Step 4: Write Neovim Config

### 4a. `~/.config/nvim/lua/config/lazy.lua`

Key change: `if vim.g.vscode` branch only loads nvim-surround, AND manually requires options + keymaps (LazyVim won't auto-load them).

```lua
if vim.g.vscode then
  require("config.options")
  require("lazy").setup({
    spec = {
      { "kylechui/nvim-surround", version = "*", event = "VeryLazy", opts = {} },
    },
    -- ...
  })
  require("config.keymaps")  -- MUST be after lazy.setup
else
  -- Full LazyVim setup
  require("lazy").setup({ ... })
end
```

### 4b. `~/.config/nvim/lua/config/keymaps.lua`

Structure: common bindings at top, then `if vim.g.vscode then ... else ... end`.

**VSCode branch** maps to `vscode.action()`:

| Category | Keys | VSCode Action |
|----------|------|---------------|
| LSP | `gd` | `editor.action.revealDefinition` |
| LSP | `gD` | `editor.action.peekDefinition` |
| LSP | `gr` | `editor.action.goToReferences` |
| LSP | `gi` | `editor.action.goToImplementation` |
| LSP | `gy` | `editor.action.goToTypeDefinition` |
| LSP | `K` | `editor.action.showHover` |
| LSP | `]d` / `[d` | `editor.action.marker.next/prev` |
| Code | `<leader>rn` | `editor.action.rename` |
| Code | `<leader>ca` | `editor.action.quickFix` |
| Code | `<leader>fm` | `editor.action.formatDocument` |
| Search | `<leader>ff` | `workbench.action.quickOpen` |
| Search | `<leader>fg` / `<leader>/` | `workbench.action.findInFiles` |
| Search | `<leader>fb` | `workbench.action.showAllEditors` |
| Search | `<leader>fr` | `workbench.action.openRecent` |
| Tree | `<leader>e` | `workbench.action.toggleSidebarVisibility` |
| Tree | `<leader>E` | `workbench.files.action.showActiveFileInExplorer` |
| Window | `Ctrl+h/j/k/l` | `workbench.action.navigate{Left,Down,Up,Right}` |
| Buffer | `H` / `L` | `workbench.action.{previous,next}Editor` |
| Buffer | `<leader>bd` | `workbench.action.closeActiveEditor` |
| Buffer | `<leader>1-4` | `workbench.action.openEditorAtIndex{1-4}` |
| Terminal | `Ctrl+\` | `workbench.action.terminal.toggleTerminal` |
| Git | `<leader>gB` | `gitlens.toggleFileBlame` |
| Git | `<leader>gd` | `workbench.view.scm` |
| Git | `<leader>gh` | `timeline.focus` |
| Git | `]c` / `[c` | `workbench.action.editor.{next,previous}Change` |
| Debug | `<leader>db` | `editor.debug.action.toggleBreakpoint` |
| Debug | `<leader>dc` | `workbench.action.debug.continue` |
| Debug | `<leader>do/di/dO` | `workbench.action.debug.step{Over,Into,Out}` |
| Debug | `<leader>dt` | `workbench.action.debug.stop` |
| Debug | `<leader>dr` | `workbench.action.debug.restart` |
| Test | `<leader>tt` | `testing.runAtCursor` |
| Test | `<leader>tf` | `testing.runCurrentFile` |
| Test | `<leader>td` | `testing.debugAtCursor` |
| Go | `<leader>cgt` | `go.add.tags` |
| Move | `Alt+j/k` | `editor.action.moveLines{Down,Up}Action` |

**Common** (both environments): `jk` → Esc, `;` → `:`

**Neovim branch**: native commands (`:m .+1`, `:w`, etc.)

### 4c. `~/.config/nvim/lua/config/options.lua`

```lua
local opt = vim.opt
opt.tabstop = 2
opt.shiftwidth = 2
opt.relativenumber = true
opt.scrolloff = 8
opt.clipboard = "unnamedplus"
opt.wrap = false
opt.undofile = true
if vim.g.vscode then opt.undofile = false end
```

## Step 5: Remove Conflicts

If settings.json has any `vim.*` keys (from VSCodeVim), remove them all. They conflict with vscode-neovim.

## Step 6: Verify

1. `Cmd+Shift+P` → `Developer: Reload Window`
2. Test `gd`, `gr`, `K` on a code symbol
3. Test `ys` (surround), `Alt+j/k` (line move)
4. Check theme rendered correctly

## Design Decisions

| Choice | Why |
|--------|-----|
| Maple Mono font | Best ligature set + cursive italic for keywords/comments |
| Catppuccin Mocha theme | High contrast, warm palette, consistent ecosystem (editor + icons) |
| `fontWeight: 400` not bold | Bold full-time causes eye fatigue, italic for emphasis instead |
| `editor.rulers: [120]` | Visual guard for line length |
| `stickyScroll` | Function context visible when scrolling deep |
| `minimap.autohide` | Save space, show on hover |
| `inlayHints: onUnlessPressed` | Type hints visible, dismiss with Ctrl to reduce noise |
| Sidebar right | Code left-aligned stays stable when toggling sidebar |
| `explorer.compactFolders: false` | Show full directory tree, easier to navigate |
