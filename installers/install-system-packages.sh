#!/usr/bin/env bash

# CLI tools installed from the system package manager (same name everywhere)
SYSTEM_PACKAGES=(
    "shellcheck"   # Shell script linter
    "bat"          # cat clone with syntax highlighting
    "glow"         # Markdown renderer for the terminal
)

# Install all packages in one go; if that fails (e.g. one package is missing
# from this distro's repos), retry one by one so the others still get installed.
# Usage: pkg_install <install command...>
pkg_install() {
    "$@" "${SYSTEM_PACKAGES[@]}" && return 0
    echo "Batch install failed, retrying packages individually..."
    local pkg failed=0
    for pkg in "${SYSTEM_PACKAGES[@]}"; do
        "$@" "$pkg" || { echo "WARNING: failed to install $pkg" >&2; failed=1; }
    done
    return "$failed"
}

install_system_packages() {
    echo "Installing system packages: ${SYSTEM_PACKAGES[*]}..."
    local status=0

    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq || return 1
        pkg_install sudo apt-get install -y -qq || status=1
    elif command -v dnf &>/dev/null; then
        pkg_install sudo dnf install -y || status=1
    elif command -v yum &>/dev/null; then
        pkg_install sudo yum install -y || status=1
    elif command -v pacman &>/dev/null; then
        pkg_install sudo pacman -S --noconfirm --needed || status=1
    elif [ "$(uname -s)" = "Darwin" ] && command -v brew &>/dev/null; then
        pkg_install brew install || status=1
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
    return "$status"
}

install_system_packages
