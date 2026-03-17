#!/usr/bin/env bash

install_lazygit() {
    echo "Installing lazygit..."

    # 1) Debian/Ubuntu (dpkg) - download from GitHub releases
    if command -v dpkg &>/dev/null; then
        ARCH=$(dpkg --print-architecture) # e.g. "arm64" or "amd64"
        # Map dpkg arch to lazygit release naming
        case "$ARCH" in
        amd64) LG_ARCH="x86_64" ;;
        arm64) LG_ARCH="arm64" ;;
        *)
            echo "Unsupported dpkg architecture: $ARCH"
            ;;
        esac

        if [ -n "$LG_ARCH" ]; then
            LATEST_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | cut -d '"' -f4 | sed 's/^v//')
            if [ -n "$LATEST_VERSION" ]; then
                LATEST_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LATEST_VERSION}/lazygit_${LATEST_VERSION}_Linux_${LG_ARCH}.tar.gz"
                echo "Downloading $LATEST_URL"
                TMP_DIR=$(mktemp -d)
                if wget -q -O "$TMP_DIR/lazygit.tar.gz" "$LATEST_URL" &&
                   tar -xzf "$TMP_DIR/lazygit.tar.gz" -C "$TMP_DIR" &&
                   sudo mv "$TMP_DIR/lazygit" /usr/local/bin/; then
                    rm -rf "$TMP_DIR"
                    echo "Successfully installed lazygit v${LATEST_VERSION}"
                    return 0
                fi
                rm -rf "$TMP_DIR"
                echo "dpkg path failed, trying fallback..."
            fi
        fi
    fi

    # 2) RHEL/Fedora (dnf copr)
    if command -v dnf &>/dev/null; then
        if sudo dnf copr enable atim/lazygit -y && sudo dnf install -y lazygit; then
            echo "Successfully installed lazygit via dnf copr"
            return 0
        fi
    fi

    # 3) Arch Linux (pacman)
    if command -v pacman &>/dev/null; then
        if sudo pacman -S --noconfirm lazygit; then
            echo "Successfully installed lazygit via pacman"
            return 0
        fi
        echo "pacman install failed, trying fallback..."
    fi

    # 4) macOS (Homebrew) — only on macOS to avoid Linuxbrew false positives
    if [ "$(uname -s)" = "Darwin" ] && command -v brew &>/dev/null; then
        if brew install lazygit; then
            echo "Successfully installed lazygit via brew"
            return 0
        fi
        echo "brew install failed, trying fallback..."
    fi

    # 5) Fallback: download and install binary tarball
    echo "Installing from binary tarball..."

    # Detect architecture
    ARCH=$(uname -m)
    OS=$(uname -s)

    # Map architecture to lazygit release pattern
    case "$ARCH" in
    x86_64) LG_ARCH="x86_64" ;;
    aarch64 | arm64) LG_ARCH="arm64" ;;
    armv7l) LG_ARCH="armv6" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        return 1
        ;;
    esac

    case "$OS" in
    Linux) LG_OS="Linux" ;;
    Darwin) LG_OS="Darwin" ;;
    *)
        echo "Unsupported OS: $OS"
        return 1
        ;;
    esac

    LATEST_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | cut -d '"' -f4 | sed 's/^v//')

    if [ -z "$LATEST_VERSION" ]; then
        echo "Failed to determine latest lazygit version"
        return 1
    fi

    BINARY_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LATEST_VERSION}/lazygit_${LATEST_VERSION}_${LG_OS}_${LG_ARCH}.tar.gz"
    TMP_DIR=$(mktemp -d)
    echo "Downloading $BINARY_URL"

    if ! wget -q -O "$TMP_DIR/lazygit.tar.gz" "$BINARY_URL"; then
        echo "Failed to download lazygit"
        rm -rf "$TMP_DIR"
        return 1
    fi

    if ! tar -xzf "$TMP_DIR/lazygit.tar.gz" -C "$TMP_DIR"; then
        echo "Failed to extract lazygit"
        rm -rf "$TMP_DIR"
        return 1
    fi

    if ! sudo mv "$TMP_DIR/lazygit" /usr/local/bin/; then
        echo "Failed to install lazygit binary"
        rm -rf "$TMP_DIR"
        return 1
    fi

    rm -rf "$TMP_DIR"
    echo "Successfully installed lazygit v${LATEST_VERSION}"
    return 0
}

# Call the function
install_lazygit
