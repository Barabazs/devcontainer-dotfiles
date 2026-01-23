#!/usr/bin/env bash

# Python CLI tools to install via uv
PYTHON_TOOLS=(
    "ast-grep-cli"   # AST grep CLI tool
    "zizmor"         # Static analysis tool for GitHub Actions
)

install_python_tools() {
    echo "Installing Python tools via uv..."

    if ! command -v uv &>/dev/null; then
        echo "Error: uv is not installed. Please install uv first."
        echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi

    for tool in "${PYTHON_TOOLS[@]}"; do
        echo "Installing $tool..."
        if uv tool install "$tool"; then
            echo "  ✓ $tool"
        else
            echo "  ✗ $tool failed"
        fi
    done

    echo "Python tools installation complete."
}

install_python_tools
