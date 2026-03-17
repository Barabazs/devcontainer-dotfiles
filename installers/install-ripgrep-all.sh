#!/usr/bin/env bash

install_ripgrep_all() {
    echo "Installing ripgrep-all..."

    # 1) macOS (Homebrew) — only on macOS to avoid Linuxbrew false positives
    if [ "$(uname -s)" = "Darwin" ] && command -v brew &>/dev/null; then
        if brew install ripgrep-all; then
            echo "Successfully installed ripgrep-all via brew"
            return 0
        fi
        echo "brew install failed, trying fallback..."
    fi

    # 2) Arch Linux (pacman)
    if command -v pacman &>/dev/null; then
        if sudo pacman -S --noconfirm ripgrep-all; then
            echo "Successfully installed ripgrep-all via pacman"
            return 0
        fi
        echo "pacman install failed, trying fallback..."
    fi

    # 3) Fallback: download and install binary tarball from GitHub
    echo "Installing from binary tarball..."

    # Detect architecture
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Map architecture to GitHub release pattern
    case "$ARCH" in
    x86_64) ARCH_PATTERN="x86_64" ;;
    aarch64 | arm64) ARCH_PATTERN="aarch64" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        return 1
        ;;
    esac

    # Determine suffix based on OS and architecture
    # Note: musl builds only available for x86_64, gnu for aarch64
    if [ "$OS" = "linux" ]; then
        if [ "$ARCH_PATTERN" = "x86_64" ]; then
            SUFFIX="unknown-linux-musl.tar.gz"
        else
            SUFFIX="unknown-linux-gnu.tar.gz"
        fi
    elif [ "$OS" = "darwin" ]; then
        SUFFIX="apple-darwin.tar.gz"
    else
        echo "Unsupported OS: $OS"
        return 1
    fi

    BINARY_URL=$(curl -s https://api.github.com/repos/phiresky/ripgrep-all/releases/latest |
        grep "browser_download_url.*${ARCH_PATTERN}-${SUFFIX}" |
        head -n1 |
        cut -d '"' -f4)

    if [ -z "$BINARY_URL" ]; then
        echo "Failed to find download URL for ripgrep-all"
        return 1
    fi

    TMP_DIR=$(mktemp -d)
    if ! wget -q -O "$TMP_DIR/rga.tar.gz" "$BINARY_URL"; then
        echo "Failed to download ripgrep-all"
        rm -rf "$TMP_DIR"
        return 1
    fi

    if ! tar -xzf "$TMP_DIR/rga.tar.gz" -C "$TMP_DIR"; then
        echo "Failed to extract ripgrep-all"
        rm -rf "$TMP_DIR"
        return 1
    fi

    if ! sudo mv "$TMP_DIR"/ripgrep_all-*/rga /usr/local/bin/ ||
       ! sudo mv "$TMP_DIR"/ripgrep_all-*/rga-preproc /usr/local/bin/; then
        echo "Failed to install ripgrep-all binaries"
        rm -rf "$TMP_DIR"
        return 1
    fi

    rm -rf "$TMP_DIR"
    echo "Successfully installed ripgrep-all binary"
    return 0
}

# Call the function
install_ripgrep_all
