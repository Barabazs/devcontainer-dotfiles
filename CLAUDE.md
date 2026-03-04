# CLAUDE.md

## Overview

Shared dotfiles and utilities for Claude Code devcontainers. Provides installation scripts, bash aliases, git configuration, and CLI tools for consistent development environments.

## Setup

- `./install.sh` — main entry point; copies dotfiles, installs tools, sets up PATH and shared config volume
- Supports Linux (Debian/RHEL/Arch) and macOS (Homebrew)
- Scripts install to `~/.local/scripts/`, tools to `~/.local/agent-tools/`

Shared config volume in `devcontainer.json`:

```json
{
  "mounts": ["source=claude-code-config,target=/claude-config,type=volume"],
  "remoteEnv": { "CLAUDE_CONFIG_DIR": "/claude-config" }
}
```

## Repository Structure

- `install.sh` — orchestrates all setup (dotfiles, scripts, installers, shared volume)
- `bash_aliases` — git shortcuts with bash-completion, navigation aliases, cwt shell integration
- `gitignore` — global gitignore template
- `scripts/` — utility scripts added to PATH
- `installers/` — multi-platform binary installers (git-delta, fd, ripgrep-all, lazygit, ast-grep, zizmor)

## Key Technical Details

- **Shared config volume**: Docker named volume at `/claude-config` preserves Claude Code settings across container rebuilds. `install.sh` symlinks `~/.claude` → `/claude-config`.
- **TMPDIR fix**: `claude-launcher` sets `TMPDIR=/claude-config/tmp` so plugin installs don't fail with EXDEV when config dir is on a different filesystem.
- **cwt shell integration**: `cwt` must be sourced via a shell function (`cwt() { source ~/.local/scripts/cwt "$@"; }`) — direct execution won't change the working directory. Completion is initialized with `_CWT_INIT=1 source`.
- **cwt config**: per-repo `git config worktree.basedir` overrides worktree location; `git config --add worktree.untrackedfiles` copies extra files into new worktrees.
- **Installers**: binary installers detect OS/arch and download latest GitHub release. Python tools (ast-grep, zizmor) install via `uv tool install`.

## Shell Scripts Conventions

- `install.sh` and installers use POSIX `#!/bin/sh`; `cwt` uses `#!/usr/bin/env bash` (needs arrays, `set -euo pipefail`)
- Scripts should handle missing dependencies gracefully and support multiple package managers
- Use `shellcheck` to lint shell scripts

## Lint

```bash
shellcheck install.sh scripts/* installers/*.sh
```
