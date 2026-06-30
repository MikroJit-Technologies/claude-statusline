#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.claude"
cp "$REPO_DIR/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
chmod +x "$HOME/.claude/statusline-command.sh"

echo "installed → $HOME/.claude/statusline-command.sh"
echo "add to ~/.claude/settings.json:"
echo '  "statusCommand": "~/.claude/statusline-command.sh"'
