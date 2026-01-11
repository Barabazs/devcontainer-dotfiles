# Devcontainer Dotfiles

This repo contains a subset of dotfiles that I use on all my devcontainers.

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
