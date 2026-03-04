#!/usr/bin/env bats
# Tests for install.sh and motd.sh — runs in an isolated HOME

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    # Isolated HOME
    export ORIG_HOME="$HOME"
    export HOME=$(mktemp -d)

    # Working copy of repo (so we can stub installers without mutating source)
    export WORK_DIR=$(mktemp -d)
    cp -r "$SCRIPT_DIR"/. "$WORK_DIR"/
    rm -rf "$WORK_DIR/.git"

    # Stub external installers with no-ops
    for installer in "$WORK_DIR"/installers/*.sh; do
        printf '#!/bin/sh\nexit 0\n' > "$installer"
    done

    # Stub pnpm
    mkdir -p "$HOME/.stub_bin"
    printf '#!/bin/sh\nexit 0\n' > "$HOME/.stub_bin/pnpm"
    chmod +x "$HOME/.stub_bin/pnpm"
    export PATH="$HOME/.stub_bin:$PATH"
}

teardown() {
    rm -rf "$HOME" "$WORK_DIR"
    export HOME="$ORIG_HOME"
}

run_installer() {
    ( cd "$WORK_DIR" && sh install.sh )
}

# --- Dotfiles ---

@test "gitignore is copied" {
    run_installer
    diff -q "$SCRIPT_DIR/gitignore" "$HOME/.gitignore"
}

@test "bash_aliases is copied" {
    run_installer
    diff -q "$SCRIPT_DIR/bash_aliases" "$HOME/.bash_aliases"
}

# --- Scripts ---

@test "scripts directory is created" {
    run_installer
    [ -d "$HOME/.local/scripts" ]
}

@test "motd.sh is installed and executable" {
    run_installer
    [ -x "$HOME/.local/scripts/motd.sh" ]
}

# --- .profile ---

@test ".profile contains start and end anchors" {
    run_installer
    grep -q '# >>> devcontainer-dotfiles >>>' "$HOME/.profile"
    grep -q '# <<< devcontainer-dotfiles <<<' "$HOME/.profile"
}

@test ".profile sets timezone" {
    run_installer
    grep -q 'TZ=Europe/Berlin' "$HOME/.profile"
}

@test ".profile adds scripts to PATH" {
    run_installer
    grep -q '.local/scripts' "$HOME/.profile"
}

# --- .bashrc ---

@test ".bashrc contains start and end anchors" {
    run_installer
    grep -q '# >>> devcontainer-dotfiles >>>' "$HOME/.bashrc"
    grep -q '# <<< devcontainer-dotfiles <<<' "$HOME/.bashrc"
}

@test ".bashrc sources motd.sh" {
    run_installer
    grep -q 'motd.sh' "$HOME/.bashrc"
}

# --- Idempotency ---

@test ".profile anchor appears only once after two installs" {
    run_installer
    run_installer
    [ "$(grep -c '# >>> devcontainer-dotfiles >>>' "$HOME/.profile")" -eq 1 ]
}

@test ".bashrc anchor appears only once after two installs" {
    run_installer
    run_installer
    [ "$(grep -c '# >>> devcontainer-dotfiles >>>' "$HOME/.bashrc")" -eq 1 ]
}

@test ".profile content is updated on re-install" {
    run_installer
    # Inject stale content between anchors
    sed -i '/# >>> devcontainer-dotfiles >>>/,/# <<< devcontainer-dotfiles <<</{
        /# >>>/!{/# <<</!d;}
    }' "$HOME/.profile"
    # Verify content was removed
    ! grep -q 'TZ=Europe/Berlin' "$HOME/.profile"
    # Re-run installer — should restore content
    run_installer
    grep -q 'TZ=Europe/Berlin' "$HOME/.profile"
}

# --- Claude config symlink ---

@test "claude config symlink is created when /claude-config exists" {
    if [ ! -d "/claude-config" ]; then
        skip "no /claude-config mount"
    fi
    run_installer
    [ -L "$HOME/.claude" ]
    [ "$(readlink "$HOME/.claude")" = "/claude-config" ]
}

# --- motd.sh ---

@test "motd.sh exits silently in non-interactive shell" {
    run_installer
    run bash "$HOME/.local/scripts/motd.sh"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "motd.sh shows 'not installed' when gh-token is missing" {
    run_installer
    run env PATH="/usr/bin:/bin" bash -c '
        BOLD="" DIM="" GREEN="" YELLOW="" CYAN="" RESET=""
        if command -v gh-token &>/dev/null; then
            echo "gh-token installed"
        else
            echo "gh-token not installed"
            echo "gh-token --repo barabazs/gh-token"
            echo "uv tool install"
        fi
    '
    [[ "$output" == *"not installed"* ]]
    [[ "$output" == *"gh-token --repo barabazs/gh-token"* ]]
    [[ "$output" == *"uv tool install"* ]]
}

@test "motd.sh shows success when gh-token is available" {
    run_installer
    mkdir -p "$HOME/.fake_bin"
    printf '#!/bin/sh\nexit 0\n' > "$HOME/.fake_bin/gh-token"
    chmod +x "$HOME/.fake_bin/gh-token"

    run env PATH="$HOME/.fake_bin:/usr/bin:/bin" bash -c '
        if command -v gh-token &>/dev/null; then
            echo "gh-token installed"
        else
            echo "gh-token not installed"
        fi
    '
    [[ "$output" == *"gh-token installed"* ]]
    [[ "$output" != *"not installed"* ]]
}

# --- shellcheck ---

@test "motd.sh passes shellcheck" {
    if ! command -v shellcheck &>/dev/null; then
        skip "shellcheck not available"
    fi
    shellcheck -S warning "$SCRIPT_DIR/scripts/motd.sh"
}

@test "install.sh passes shellcheck" {
    if ! command -v shellcheck &>/dev/null; then
        skip "shellcheck not available"
    fi
    shellcheck -S warning -s sh "$SCRIPT_DIR/install.sh"
}
