# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains a Neovim configuration with modular organization:

- `init.lua`: Main entry point, bootstraps the configuration
- `lua/brpol/`: Core user-specific configurations
- `lua/plugins/`: Plugin configurations organized by functionality

## Key Configuration Details

### Core Configuration Files

- `lua/brpol/init.lua`: Primary configuration file, sets up leader keys, package manager, and basic Neovim options
- `lua/brpol/remap.lua`: Defines key mappings using which-key
- `lua/brpol/commands.lua`: Contains custom commands
- `lua/brpol/vscode_theme.lua`: VSCode-inspired theme configuration

### Plugin Organization

Plugins are organized into functional groups in `lua/plugins/`:
- `autocomplete_lsp_debug_snippets.lua`: LSP, code completion, and snippets
- `debugging.lua`: Debugging setup
- `git.lua`: Git integrations
- `languages.lua`: Language-specific configurations
- `terminal_and_repl.lua`: Terminal and REPL support
- `themes_and_ui.lua`: UI customizations

## Important Commands

### Plugin Management

```
:Lazy                    # Open Lazy plugin manager
:LazyUpdate              # Update plugins
:LazySync                # Sync plugins
:checkhealth             # Check Neovim health
```

### LSP Commands

```
:Mason                   # Open Mason LSP/DAP manager
:LspInfo                 # Show active language servers
:LspRestart              # Restart language servers
```

### Formatting

```
:FormatEnable            # Enable autoformatting
:FormatDisable           # Disable autoformatting
```

### Common Keybindings

- Leader key: `,` (comma)
- Local leader: `<` (less than)
- `jj`: Escape from insert mode
- `<leader>f`: Find/file operations (Telescope)
- `<leader>g`: Git operations
- `<leader>v`: LSP/IDE operations
- `<leader>R`: Refactoring operations
- `<leader>%`: Copy full path to clipboard

## Environment Setup

- The configuration automatically sets up a Python virtual environment at `~/.config/nvim/.venv` for Python plugins
- Plugin management is handled by `lazy.nvim`
- Platform-specific configurations for Windows and WSL are included
