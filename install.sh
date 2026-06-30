#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.claude/statusline-command.sh"
SETTINGS="$HOME/.claude/settings.json"

# ── dependency check ──────────────────────────────────────────
missing=()
command -v jq  >/dev/null 2>&1 || missing+=("jq")
command -v git >/dev/null 2>&1 || missing+=("git")
command -v awk >/dev/null 2>&1 || missing+=("awk")

if [ ${#missing[@]} -gt 0 ]; then
  echo "⚠  Missing: ${missing[*]}"
  if command -v brew >/dev/null 2>&1; then
    echo "   brew install ${missing[*]}"
  elif command -v apt-get >/dev/null 2>&1; then
    echo "   sudo apt-get install ${missing[*]}"
  elif command -v dnf >/dev/null 2>&1; then
    echo "   sudo dnf install ${missing[*]}"
  fi
  echo ""
fi

# ── install script ────────────────────────────────────────────
mkdir -p "$HOME/.claude"
cp "$REPO_DIR/statusline-command.sh" "$DEST"
chmod +x "$DEST"
echo "✓ installed → $DEST"

# ── patch settings.json ───────────────────────────────────────
SNIPPET='"statusLine": {"type": "command","command": "bash '"$DEST"'"}'

if [ -f "$SETTINGS" ]; then
  if grep -q '"statusLine"' "$SETTINGS" 2>/dev/null; then
    echo "✓ settings.json already has statusLine — skipping"
  else
    # inject before closing }
    if command -v jq >/dev/null 2>&1; then
      tmp=$(mktemp)
      jq '. + {"statusLine": {"type": "command","command": "bash '"$DEST"'"}}' \
        "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
      echo "✓ patched $SETTINGS"
    else
      echo ""
      echo "Add to $SETTINGS manually:"
      echo "  $SNIPPET"
    fi
  fi
else
  cat > "$SETTINGS" <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "bash $DEST"
  }
}
EOF
  echo "✓ created $SETTINGS"
fi

echo ""
echo "Reload Claude Code to activate the statusline."
