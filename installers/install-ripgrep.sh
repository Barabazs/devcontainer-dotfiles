#!/usr/bin/env bash

install_ripgrep() {
    echo "Installing ripgrep..."

    # 1) Debian/Ubuntu (apt, then GitHub .deb fallback)
    if command -v apt-get &>/dev/null; then
        if sudo apt-get update -qq && sudo apt-get install -y -qq ripgrep; then
            echo "Successfully installed ripgrep via apt"
            return 0
        fi
        echo "apt install failed, trying GitHub .deb..."
    fi
    
    if command -v dpkg &>/dev/null; then
        ARCH=$(dpkg --print-architecture) # e.g. "arm64" or "amd64"
        LATEST_URL=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep "browser_download_url.*_${ARCH}\.deb" | head -n 1 | cut -d '"' -f4)
        if [ -n "$LATEST_URL" ]; then
            echo "Downloading $LATEST_URL"
            if wget -q -O /tmp/ripgrep-latest.deb "$LATEST_URL" &&
               sudo dpkg -i /tmp/ripgrep-latest.deb; then
                rm -f /tmp/ripgrep-latest.deb
                echo "Successfully installed ripgrep via GitHub .deb"
                return 0
            fi
            rm -f /tmp/ripgrep-latest.deb
            echo "dpkg install failed, trying fallback..."
        fi
    fi

    # 2) RHEL/Fedora (dnf/yum)
    if command -v dnf &>/dev/null; then
        if sudo dnf install -y ripgrep; then
            echo "Successfully installed ripgrep via dnf"
            return 0
        fi
    elif command -v yum &>/dev/null; then
        if sudo yum install -y ripgrep; then
            echo "Successfully installed ripgrep via yum"
            return 0
        fi
    fi

    # 3) Arch Linux (pacman)
    if command -v pacman &>/dev/null; then
        if sudo pacman -S --noconfirm ripgrep; then
            echo "Successfully installed ripgrep via pacman"
            return 0
        fi
        echo "pacman install failed, trying fallback..."
    fi

    # 4) macOS (Homebrew) — only on macOS to avoid Linuxbrew false positives
    if [ "$(uname -s)" = "Darwin" ] && command -v brew &>/dev/null; then
        if brew install ripgrep; then
            echo "Successfully installed ripgrep via brew"
            return 0
        fi
        echo "brew install failed, trying fallback..."
    fi

    # 5) Fallback: download and install binary tarball
    echo "Installing from binary tarball..."

    # Detect architecture
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Map architecture to GitHub release pattern
    case "$ARCH" in
    x86_64) ARCH_PATTERN="x86_64" ;;
    aarch64 | arm64) ARCH_PATTERN="aarch64" ;;
    armv7l) ARCH_PATTERN="armv7" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        return 1
        ;;
    esac

    if [ "$OS" = "linux" ]; then
        SUFFIX="linux-gnu.tar.gz"
    elif [ "$OS" = "darwin" ]; then
        SUFFIX="apple-darwin.tar.gz"
    else
        echo "Unsupported OS: $OS"
        return 1
    fi

    BINARY_URL=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest |
        grep "browser_download_url.*${ARCH_PATTERN}.*${SUFFIX}" |
        head -n1 |
        cut -d '"' -f4)

    if [ -z "$BINARY_URL" ]; then
        echo "Failed to find download URL for ripgrep"
        return 1
    fi

    TMP_DIR=$(mktemp -d)
    if ! wget -q -O "$TMP_DIR/ripgrep.tar.gz" "$BINARY_URL"; then
        echo "Failed to download ripgrep"
        rm -rf "$TMP_DIR"
        return 1
    fi

    if ! tar -xzf "$TMP_DIR/ripgrep.tar.gz" -C "$TMP_DIR"; then
        echo "Failed to extract ripgrep"
        rm -rf "$TMP_DIR"
        return 1
    fi

    if ! sudo mv "$TMP_DIR"/ripgrep*/rg /usr/local/bin/; then
        echo "Failed to install ripgrep binary"
        rm -rf "$TMP_DIR"
        return 1
    fi

    rm -rf "$TMP_DIR"
    echo "Successfully installed ripgrep binary"
    return 0
}

# Call the function
install_ripgrep
