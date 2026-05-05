#!/usr/bin/env bash
# Bootstrap dotfiles on a machine.
# Run from the repo root:  ./bootstrap.sh
#
# Copies config files from this repo into the locations the tools expect.
# Idempotent — safe to re-run. Existing files are backed up with a timestamp.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
CONFIG_HOME="$HOME/.config"

echo "[bootstrap] Source: $DOTFILES_DIR"
echo "[bootstrap] Targets: $CLAUDE_HOME, $CONFIG_HOME, $HOME"
echo

mkdir -p "$CLAUDE_HOME/bin"
mkdir -p "$CLAUDE_HOME/skills/doc"
mkdir -p "$CONFIG_HOME"

backup_if_exists() {
    local target="$1"
    if [ -f "$target" ]; then
        local backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
        cp "$target" "$backup"
        echo "[bootstrap]   backed up existing -> $(basename "$backup")"
    fi
}

install_file() {
    local src="$1"
    local dst="$2"
    if [ ! -f "$src" ]; then
        echo "[bootstrap] SKIP (missing source): $src"
        return
    fi
    backup_if_exists "$dst"
    cp "$src" "$dst"
    echo "[bootstrap] installed: $dst"
}

install_file "$DOTFILES_DIR/claude/CLAUDE.md"             "$CLAUDE_HOME/CLAUDE.md"
install_file "$DOTFILES_DIR/claude/statusline-command.sh" "$CLAUDE_HOME/statusline-command.sh"
install_file "$DOTFILES_DIR/claude/bin/jq.exe"            "$CLAUDE_HOME/bin/jq.exe"
install_file "$DOTFILES_DIR/claude/skills/doc/SKILL.md"   "$CLAUDE_HOME/skills/doc/SKILL.md"

install_file "$DOTFILES_DIR/shell/.bashrc"                "$HOME/.bashrc"
install_file "$DOTFILES_DIR/shell/starship.toml"          "$CONFIG_HOME/starship.toml"

# Starship binary isn't shipped with this repo (5MB+, version-pinned downloads).
# Warn so the user knows the prompt won't render until they install it.
if ! command -v starship >/dev/null 2>&1; then
    echo
    echo "[bootstrap] WARN: starship not found on PATH."
    echo "[bootstrap]       Install from https://starship.rs to activate the prompt."
fi

echo
echo "[bootstrap] Done. Restart Claude Code and open a new terminal to apply."
