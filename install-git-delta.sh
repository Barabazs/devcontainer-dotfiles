#!/bin/env bash

install_delta() {
    echo "Installing git-delta..."

    # Determine available package managers
    if command -v apt-get &>/dev/null || command -v dpkg &>/dev/null; then
        # Debian/Ubuntu based
        LATEST_URL=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep "browser_download_url.*_amd64.deb" | grep -v "musl" | head -n 1 | cut -d '"' -f 4)
        if [ -n "$LATEST_URL" ]; then
            wget -O /tmp/git-delta-latest.deb "$LATEST_URL"
            sudo dpkg -i /tmp/git-delta-latest.deb
            rm /tmp/git-delta-latest.deb
            echo "Successfully installed git-delta via dpkg"
            return 0
        fi
    elif command -v dnf &>/dev/null || command -v yum &>/dev/null; then
        # RHEL/Fedora based
        if command -v dnf &>/dev/null; then
            sudo dnf install -y git-delta
        else
            sudo yum install -y git-delta
        fi
        echo "Successfully installed git-delta via dnf/yum"
        return 0
    elif command -v pacman &>/dev/null; then
        # Arch based
        sudo pacman -S --noconfirm git-delta
        echo "Successfully installed git-delta via pacman"
        return 0
    elif command -v brew &>/dev/null; then
        # macOS (Homebrew)
        brew install git-delta
        echo "Successfully installed git-delta via brew"
        return 0
    fi

    # Fallback to binary installation if no package manager worked
    echo "No suitable package manager found, installing binary directly..."

    # Detect architecture
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Map architecture to GitHub release pattern
    case "$ARCH" in
    x86_64) ARCH_PATTERN="x86_64" ;;
    aarch64 | arm64) ARCH_PATTERN="arm64" ;;
    armv7l) ARCH_PATTERN="armv7" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        return 1
        ;;
    esac

    # Choose appropriate binary based on OS
    if [ "$OS" = "linux" ]; then
        BINARY_URL=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep "browser_download_url.*${ARCH_PATTERN}.*linux-gnu.tar.gz" | head -n 1 | cut -d '"' -f 4)
    elif [ "$OS" = "darwin" ]; then
        BINARY_URL=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep "browser_download_url.*${ARCH_PATTERN}.*apple-darwin.tar.gz" | head -n 1 | cut -d '"' -f 4)
    else
        echo "Unsupported OS: $OS"
        return 1
    fi

    if [ -n "$BINARY_URL" ]; then
        TMP_DIR=$(mktemp -d)
        wget -O "$TMP_DIR/delta.tar.gz" "$BINARY_URL"
        tar -xzf "$TMP_DIR/delta.tar.gz" -C "$TMP_DIR"
        sudo mv "$TMP_DIR"/delta*/delta /usr/local/bin/
        rm -rf "$TMP_DIR"
        echo "Successfully installed git-delta binary"
        return 0
    fi

    echo "Failed to install git-delta"
    return 1
}

# Call the function
install_delta
