#!/usr/bin/env bash

install_ripgrep_all() {
    echo "Installing ripgrep-all..."

    # 1) macOS (Homebrew)
    if command -v brew &>/dev/null; then
        brew install ripgrep-all
        echo "Successfully installed ripgrep-all via brew"
        return 0
    fi

    # 2) Arch Linux (pacman)
    if command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm ripgrep-all
        echo "Successfully installed ripgrep-all via pacman"
        return 0
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
    if [ "$OS" == "linux" ]; then
        if [ "$ARCH_PATTERN" == "x86_64" ]; then
            SUFFIX="unknown-linux-musl.tar.gz"
        else
            SUFFIX="unknown-linux-gnu.tar.gz"
        fi
    elif [ "$OS" == "darwin" ]; then
        SUFFIX="apple-darwin.tar.gz"
    else
        echo "Unsupported OS: $OS"
        return 1
    fi

    BINARY_URL=$(curl -s https://api.github.com/repos/phiresky/ripgrep-all/releases/latest |
        grep "browser_download_url.*${ARCH_PATTERN}-${SUFFIX}" |
        head -n1 |
        cut -d '"' -f4)

    if [ -n "$BINARY_URL" ]; then
        TMP_DIR=$(mktemp -d)
        wget -O "$TMP_DIR/rga.tar.gz" "$BINARY_URL"
        tar -xzf "$TMP_DIR/rga.tar.gz" -C "$TMP_DIR"
        sudo mv "$TMP_DIR"/ripgrep_all-*/rga /usr/local/bin/
        sudo mv "$TMP_DIR"/ripgrep_all-*/rga-preproc /usr/local/bin/
        rm -rf "$TMP_DIR"
        echo "Successfully installed ripgrep-all binary"
        return 0
    fi

    echo "Failed to install ripgrep-all"
    return 1
}

# Call the function
install_ripgrep_all
