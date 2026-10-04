#!/usr/bin/env bash

# Node CLI tools to install globally via pnpm
NODE_TOOLS=(
    "@doist/todoist-cli"   # Todoist CLI (td); needs Node >= 24
)

install_node_tools() {
    echo "Installing Node tools via pnpm..."

    if ! command -v pnpm &>/dev/null; then
        echo "Error: pnpm is not installed. Please install pnpm first."
        echo "  corepack enable pnpm"
        return 1
    fi

    # pnpm refuses global installs unless its global bin dir is on PATH.
    # Keep in sync with the PNPM_HOME/PATH lines in install.sh's .profile block.
    export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
    export PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH"

    # 7-day cooldown, passed explicitly: pnpm <11 ignores ~/.config/pnpm/config.yaml
    # (written by install.sh); the CLI flag works on both (verified on pnpm 10.34 and 12.8)
    local cooldown="--config.minimum-release-age=10080" # minutes

    local tool failed=0
    for tool in "${NODE_TOOLS[@]}"; do
        echo "Installing $tool..."
        if pnpm add -g "$cooldown" "$tool"; then
            echo "  ✓ $tool"
        else
            echo "  ✗ $tool failed"
            failed=1
        fi
    done

    echo "Node tools installation complete."
    return "$failed"
}

install_node_tools
