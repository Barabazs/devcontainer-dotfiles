#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Ensure Python stdlib is available (Debian Trixie ships python3-minimal without it)
if ! python3 -c "import shutil" 2>/dev/null; then
    echo "Installing Python stdlib (missing in python3-minimal)..."
    sudo apt-get update -qq && sudo apt-get install -y -qq libpython3-stdlib >/dev/null
fi

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

# Upsert a managed block between start/end anchors in a file.
# Usage: upsert_block <file> <content>
ANCHOR_START='# >>> devcontainer-dotfiles >>>'
ANCHOR_END='# <<< devcontainer-dotfiles <<<'

upsert_block() {
    target="$1"
    content="$2"
    block="$(printf '%s\n%s\n%s' "$ANCHOR_START" "$content" "$ANCHOR_END")"

    if [ ! -f "$target" ]; then
        printf '\n%s\n' "$block" >> "$target"
    elif grep -q "$ANCHOR_START" "$target"; then
        # Replace existing block
        sed -i "/$ANCHOR_START/,/$ANCHOR_END/c\\
$(echo "$block" | sed 's/$/\\/' | sed '$ s/\\$//')" "$target"
    else
        printf '\n%s\n' "$block" >> "$target"
    fi
}

# Manage .profile block
upsert_block ~/.profile '
if [ -d "${HOME}/.local/scripts" ] ; then
    PATH="${HOME}/.local/scripts:$PATH"
fi

# Agent tools for Claude Code (web search, browser automation, content extraction)
for tool in brave-search browser-tools search-tools; do
    if [ -d "${HOME}/.local/agent-tools/$tool" ] ; then
        PATH="${PATH}:${HOME}/.local/agent-tools/$tool"
    fi
done

export TZ=Europe/Berlin'

# Manage .bashrc block
upsert_block ~/.bashrc '# shellcheck source=/dev/null
[ -f "${HOME}/.local/scripts/motd.sh" ] && . "${HOME}/.local/scripts/motd.sh"

# Prevent host git credentials (e.g. VS Code GIT_ASKPASS) from being used as fallback.
# Git auth goes exclusively through the gh-token credential helper (gh-token setup-git).
export GIT_ASKPASS=/bin/false'
# chmod the scripts
chmod +x ~/.local/scripts/*

# Install CLI tools (non-fatal: log failures but continue)
for installer in \
    install-git-delta.sh \
    install-fd.sh \
    install-ripgrep-all.sh \
    install-lazygit.sh \
    install-python-tools.sh \
; do
    if ! bash "$SCRIPT_DIR/installers/$installer"; then
        echo "WARNING: $installer failed" >&2
    fi
done

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
