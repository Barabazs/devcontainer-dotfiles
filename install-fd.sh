#!/usr/bin/env bash

install_fd() {
    echo "Installing fd..."

    # 1) Debian/Ubuntu (dpkg)
    if command -v dpkg &>/dev/null; then
        ARCH=$(dpkg --print-architecture) # e.g. "arm64" or "amd64"
        LATEST_URL=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep "browser_download_url.*_${ARCH}\.deb" | grep -v "musl" | head -n 1 | cut -d '"' -f4)
        if [ -n "$LATEST_URL" ]; then
            # Remove apt version if installed (conflicts with GitHub release)
            if dpkg -l fd-find &>/dev/null; then
                echo "Removing old fd-find package..."
                sudo apt-get remove -y fd-find
            fi
            echo "Downloading $LATEST_URL"
            wget -O /tmp/fd-latest.deb "$LATEST_URL"
            if sudo dpkg -i /tmp/fd-latest.deb; then
                rm /tmp/fd-latest.deb
                echo "Successfully installed fd via dpkg"
                return 0
            else
                echo "dpkg failed (possibly zstd compression not supported), falling back to tarball..."
                rm -f /tmp/fd-latest.deb
            fi
        fi
    fi

    # 2) RHEL/Fedora (dnf/yum)
    if command -v dnf &>/dev/null; then
        sudo dnf install -y fd-find && {
            echo "Successfully installed fd via dnf"
            return 0
        }
    elif command -v yum &>/dev/null; then
        sudo yum install -y fd-find && {
            echo "Successfully installed fd via yum"
            return 0
        }
    fi

    # 3) Arch Linux (pacman)
    if command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm fd
        echo "Successfully installed fd via pacman"
        return 0
    fi

    # 4) macOS (Homebrew)
    if command -v brew &>/dev/null; then
        brew install fd
        echo "Successfully installed fd via brew"
        return 0
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

    if [ "$OS" == "linux" ]; then
        SUFFIX="linux-gnu.tar.gz"
    elif [ "$OS" == "darwin" ]; then
        SUFFIX="apple-darwin.tar.gz"
    else
        echo "Unsupported OS: $OS"
        return 1
    fi

    BINARY_URL=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest |
        grep "browser_download_url.*${ARCH_PATTERN}.*${SUFFIX}" |
        head -n1 |
        cut -d '"' -f4)

    if [ -n "$BINARY_URL" ]; then
        TMP_DIR=$(mktemp -d)
        wget -O "$TMP_DIR/fd.tar.gz" "$BINARY_URL"
        tar -xzf "$TMP_DIR/fd.tar.gz" -C "$TMP_DIR"
        sudo mv "$TMP_DIR"/fd*/fd /usr/local/bin/
        rm -rf "$TMP_DIR"
        echo "Successfully installed fd binary"
        return 0
    fi

    echo "Failed to install fd"
    return 1
}

# Call the function
install_fd
