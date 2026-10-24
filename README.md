# Devcontainer Dotfiles

This repo contains a subset of dotfiles that I use on all my devcontainers.

## Required Devcontainer Features

The dotfiles install CLI tools on top of runtimes they don't install themselves. Add these features to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:2": {},
    "ghcr.io/devcontainers-extra/features/uv:1": {}
  }
}
```

- **node** (>= 24, brings pnpm): Node tools such as `td` (todoist-cli)
- **uv**: Python tools (ast-grep, zizmor, prek)

Without them, those installers are skipped. The warning only shows up in the container creation log, so the shell MOTD also reports a missing `td` and how to fix it.

## Shared Claude Code Config

The install script supports sharing Claude Code configuration across containers via a named Docker volume. This preserves settings, history, and credentials between container rebuilds and across different projects.

Add the following to your `devcontainer.json`:

```json
{
  "mounts": [
    "source=claude-code-config,target=/claude-config,type=volume"
  ],
  "remoteEnv": {
    "CLAUDE_CONFIG_DIR": "/claude-config"
  }
}
```

The install script will automatically:
- Set permissions on the shared volume
- Create a symlink from `~/.claude` to `/claude-config`

This works for any container user (`vscode`, `node`, `root`, etc.).
