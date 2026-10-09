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

# pnpm global tools (e.g. td); pnpm 11+ links bins into $PNPM_HOME/bin, older into $PNPM_HOME
export PNPM_HOME="${PNPM_HOME:-${HOME}/.local/share/pnpm}"
PATH="${PATH}:${PNPM_HOME}/bin:${PNPM_HOME}"

export TZ=Europe/Berlin'

# Manage .bashrc block
upsert_block ~/.bashrc '# shellcheck source=/dev/null
[ -f "${HOME}/.local/scripts/motd.sh" ] && . "${HOME}/.local/scripts/motd.sh"

# Prevent host git credentials (e.g. VS Code GIT_ASKPASS) from being used as fallback.
# Git auth goes exclusively through the gh-token credential helper (gh-token setup-git).
export GIT_ASKPASS=/bin/false'
# chmod the scripts
chmod +x ~/.local/scripts/*

# Configure uv: 7-day dependency cooldown (supply chain protection)
mkdir -p ~/.config/uv
cat > ~/.config/uv/uv.toml <<'EOF'
# 7-day dependency cooldown (supply chain protection)
# Applies to tool commands (uv run on PEP 723 inline scripts)
exclude-newer = "1 week"
EOF

# Configure npm: 7-day dependency cooldown (supply chain protection)
cat > ~/.npmrc <<'EOF'
# 7-day dependency cooldown (supply chain protection)
min-release-age=7 # days
EOF

# Configure pnpm: 7-day dependency cooldown (supply chain protection)
mkdir -p ~/.config/pnpm
cat > ~/.config/pnpm/config.yaml <<'EOF'
# 7-day dependency cooldown (supply chain protection)
minimumReleaseAge: 10080 # minutes
minimumReleaseAgeStrict: true
EOF

# Configure glow: wrap at terminal width (config width 0 = terminal width,
# capped at 120 by glow; unlike `-w 0` on the CLI, which disables wrapping)
mkdir -p ~/.config/glow
cat > ~/.config/glow/glow.yml <<'EOF'
# style name or JSON path (pinned dark theme; skips auto light/dark detection)
style: "dracula"
# word-wrap at width (0 = terminal width, max 120)
width: 0
# mouse wheel scrolling (TUI-mode only; drag-select then needs prefix-[ or Option-drag)
mouse: true
EOF

# Install CLI tools (non-fatal: log failures but continue)
for installer in \
    install-git-delta.sh \
    install-ripgrep.sh \
    install-fd.sh \
    install-ripgrep-all.sh \
    install-lazygit.sh \
    install-python-tools.sh \
    install-node-tools.sh \
    install-system-packages.sh \
; do
    if ! bash "$SCRIPT_DIR/installers/$installer"; then
        echo "WARNING: $installer failed" >&2
    fi
done

# Git config. VS Code copies the host ~/.gitconfig into the container; the devcontainer
# CLI doesn't, so set what this repo provides. Identity (user.name/email) stays host-side.
# Git only reads ~/.config/git/ignore by default; point it at the copied ~/.gitignore.
# shellcheck disable=SC2088 # literal ~: git expands it in pathname values
git config --global core.excludesfile '~/.gitignore'
if command -v delta >/dev/null 2>&1; then
    git config --global core.pager delta
    git config --global interactive.diffFilter 'delta --color-only'
    git config --global delta.navigate true
fi

# Initialize shared Claude config volume (if mounted at /claude-config)
if [ -d "/claude-config" ]; then
    chmod -R 777 /claude-config 2>/dev/null || true
    # Restore sticky/private bits on the sockets path: uds-messaging (cross-session
    # messaging) refuses to bind if any component is world-writable without sticky.
    mkdir -p /claude-config/tmp
    chmod 1777 /claude-config /claude-config/tmp 2>/dev/null || true
    chmod 700 /claude-config/tmp/cc-socks 2>/dev/null || true
    # Remove existing .claude if it's a directory (not a symlink)
    if [ -e "$HOME/.claude" ] && [ ! -L "$HOME/.claude" ]; then
        rm -rf "$HOME/.claude"
    fi
    ln -sfn /claude-config "$HOME/.claude"
    echo "Claude config: Linked ~/.claude -> /claude-config"
fi
