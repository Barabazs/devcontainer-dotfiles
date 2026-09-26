#!/usr/bin/env bash

# CLI tools installed from the system package manager (same name everywhere)
SYSTEM_PACKAGES=(
    "shellcheck"   # Shell script linter
    "bat"          # cat clone with syntax highlighting
)

install_system_packages() {
    echo "Installing system packages: ${SYSTEM_PACKAGES[*]}..."

    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq "${SYSTEM_PACKAGES[@]}" || return 1
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "${SYSTEM_PACKAGES[@]}" || return 1
    elif command -v yum &>/dev/null; then
        sudo yum install -y "${SYSTEM_PACKAGES[@]}" || return 1
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm --needed "${SYSTEM_PACKAGES[@]}" || return 1
    elif [ "$(uname -s)" = "Darwin" ] && command -v brew &>/dev/null; then
        brew install "${SYSTEM_PACKAGES[@]}" || return 1
    else
        echo "No supported package manager found"
        return 1
    fi

    # Debian/Ubuntu ship bat as `batcat` (name clash with bacula's `bat`)
    if ! command -v bat &>/dev/null && command -v batcat &>/dev/null; then
        mkdir -p ~/.local/bin
        ln -sf "$(command -v batcat)" ~/.local/bin/bat
        echo "Linked ~/.local/bin/bat -> batcat"
    fi

    echo "System packages installation complete."
}

install_system_packages
