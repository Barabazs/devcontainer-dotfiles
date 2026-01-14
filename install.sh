#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Copy the dotfiles
cp gitignore ~/.gitignore

# Copy the bash_aliases
cp bash_aliases ~/.bash_aliases

# Copy the scripts
mkdir -p ~/.local
cp -r scripts ~/.local/

# Install agent-tools (vendored CLI tools for Claude Code)
# Source: https://github.com/Barabazs/agent-tools (forked from badlogic/agent-tools)
cd "$SCRIPT_DIR" && git submodule update --init --recursive 2>/dev/null
mkdir -p ~/.local/agent-tools

for tool in brave-search browser-tools search-tools; do
    if [ -d "$SCRIPT_DIR/agent-tools/$tool" ]; then
        cp -r "$SCRIPT_DIR/agent-tools/$tool" ~/.local/agent-tools/
        cd ~/.local/agent-tools/$tool && pnpm install --silent 2>/dev/null
        chmod +x ~/.local/agent-tools/$tool/*.js
        echo "Installed agent-tools ($tool)"
    fi
done

# Append to .profile
cat <<'EOF' >>~/.profile
if [ -d "${HOME}/.local/scripts" ] ; then
    PATH="${HOME}/.local/scripts:$PATH"
fi

# Agent tools for Claude Code (web search, browser automation, content extraction)
for tool in brave-search browser-tools search-tools; do
    if [ -d "${HOME}/.local/agent-tools/$tool" ] ; then
        PATH="${PATH}:${HOME}/.local/agent-tools/$tool"
    fi
done

export TZ=Europe/Berlin
EOF

# chmod the scripts
chmod +x ~/.local/scripts/*

# Install git-delta
sh "$SCRIPT_DIR/installers/install-git-delta.sh"

# Install fd (fast find alternative)
sh "$SCRIPT_DIR/installers/install-fd.sh"

# Install lazygit (terminal UI for git)
sh "$SCRIPT_DIR/installers/install-lazygit.sh"

# Initialize shared Claude config volume (if mounted at /claude-config)
if [ -d "/claude-config" ]; then
    chmod -R 777 /claude-config 2>/dev/null || true
    # Remove existing .claude if it's a directory (not a symlink)
    if [ -e "$HOME/.claude" ] && [ ! -L "$HOME/.claude" ]; then
        rm -rf "$HOME/.claude"
    fi
    ln -sfn /claude-config "$HOME/.claude"
    echo "Claude config: Linked ~/.claude -> /claude-config"
fi
