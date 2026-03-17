#!/usr/bin/env bash

install_fd() {
    echo "Installing fd..."

    # 1) Debian/Ubuntu (dpkg)
    if command -v dpkg &>/dev/null; then
        ARCH=$(dpkg --print-architecture) # e.g. "arm64" or "amd64"
        LATEST_URL=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep "browser_download_url.*_${ARCH}\.deb" | grep -v "musl" | head -n 1 | cut -d '"' -f4)
        if [ -n "$LATEST_URL" ]; then
            # Ensure zstd is installed (needed for newer .deb compression)
            if ! command -v zstd &>/dev/null; then
                echo "Installing zstd for .deb extraction..."
                sudo apt-get update && sudo apt-get install -y zstd
            fi
            # Remove apt version if installed (conflicts with GitHub release)
            if dpkg -l fd-find &>/dev/null; then
                echo "Removing old fd-find package..."
                sudo apt-get remove -y fd-find
            fi
            echo "Downloading $LATEST_URL"
            if wget -q -O /tmp/fd-latest.deb "$LATEST_URL" &&
               sudo dpkg -i /tmp/fd-latest.deb; then
                rm -f /tmp/fd-latest.deb
                echo "Successfully installed fd via dpkg"
                return 0
            fi
            rm -f /tmp/fd-latest.deb
            echo "dpkg install failed, trying fallback..."
        fi
    fi

    # 2) RHEL/Fedora (dnf/yum)
    if command -v dnf &>/dev/null; then
        if sudo dnf install -y fd-find; then
            echo "Successfully installed fd via dnf"
            return 0
        fi
    elif command -v yum &>/dev/null; then
        if sudo yum install -y fd-find; then
            echo "Successfully installed fd via yum"
            return 0
        fi
    fi

    # 3) Arch Linux (pacman)
    if command -v pacman &>/dev/null; then
        if sudo pacman -S --noconfirm fd; then
            echo "Successfully installed fd via pacman"
            return 0
        fi
        echo "pacman install failed, trying fallback..."
    fi

    # 4) macOS (Homebrew) — only on macOS to avoid Linuxbrew false positives
    if [ "$(uname -s)" = "Darwin" ] && command -v brew &>/dev/null; then
        if brew install fd; then
            echo "Successfully installed fd via brew"
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

    BINARY_URL=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest |
        grep "browser_download_url.*${ARCH_PATTERN}.*${SUFFIX}" |
        head -n1 |
        cut -d '"' -f4)

    if [ -z "$BINARY_URL" ]; then
        echo "Failed to find download URL for fd"
        return 1
    fi

    TMP_DIR=$(mktemp -d)
    if ! wget -q -O "$TMP_DIR/fd.tar.gz" "$BINARY_URL"; then
        echo "Failed to download fd"
        rm -rf "$TMP_DIR"
        return 1
    fi

    if ! tar -xzf "$TMP_DIR/fd.tar.gz" -C "$TMP_DIR"; then
        echo "Failed to extract fd"
        rm -rf "$TMP_DIR"
        return 1
    fi

    if ! sudo mv "$TMP_DIR"/fd*/fd /usr/local/bin/; then
        echo "Failed to install fd binary"
        rm -rf "$TMP_DIR"
        return 1
    fi

    rm -rf "$TMP_DIR"
    echo "Successfully installed fd binary"
    return 0
}

# Call the function
install_fd
