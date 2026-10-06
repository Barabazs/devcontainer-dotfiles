#!/bin/bash
# MOTD - shown on interactive shell startup in devcontainers

# Only run in interactive shells
if [[ $- != *i* ]]; then
    return 2>/dev/null || exit 0
fi

# Colors
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo ""
echo -e "${BOLD}${CYAN}devcontainer-dotfiles${RESET} ${DIM}loaded${RESET}"

# Check gh-token availability
if command -v gh-token &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} gh-token installed"

    # Check git credential helper
    if git config --global credential.helper 2>/dev/null | grep -q "gh-token"; then
        echo -e "  ${GREEN}✓${RESET} git credential helper configured"
    else
        echo -e "  ${YELLOW}✗${RESET} git credential helper not configured"
        echo -e "    ${DIM}Run: gh-token setup-git${RESET}"
    fi

    # Check gh shim: bare `gh` runs via `gh-token gh` and gets a token
    if head -c 4096 "$(command -v gh 2>/dev/null)" 2>/dev/null | grep -q "gh-token-shim"; then
        echo -e "  ${GREEN}✓${RESET} gh CLI gets tokens from gh-token"
    else
        echo -e "  ${YELLOW}✗${RESET} gh CLI has no token"
        echo -e "    ${DIM}Run: gh-token setup-gh${RESET}"
    fi
else
    echo -e "  ${YELLOW}✗${RESET} gh-token not installed"
    echo -e "    ${DIM}On the host, run:${RESET}"
    echo -e "    ${DIM}  gh-token --repo barabazs/gh-token${RESET}"
    echo -e "    ${DIM}Then in this container:${RESET}"
    echo -e "    ${DIM}  read -rsp 'Token: ' T && uv tool install git+https://x-access-token:\${T}@github.com/barabazs/gh-token.git && gh-token setup-git && gh-token setup-gh${RESET}"
fi

echo ""
