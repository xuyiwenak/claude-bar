#!/usr/bin/env bash
# claude-bar uninstaller

set -e

CLAUDE_DIR="$HOME/.claude"
TARGET="$CLAUDE_DIR/statusline-command.sh"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "==> Uninstalling claude-bar..."

# Remove script
if [ -f "$TARGET" ]; then
  rm "$TARGET"
  echo "    Removed $TARGET"
fi

# Remove statusLine key from settings.json
if [ -f "$SETTINGS" ]; then
  python3 - "$SETTINGS" << 'PYEOF'
import json, sys

path = sys.argv[1]
with open(path) as f:
    settings = json.load(f)

settings.pop("statusLine", None)

with open(path, "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(f"    Removed statusLine from {path}")
PYEOF
fi

echo ""
echo "✓ Uninstalled. Restart Claude Code to revert to the default status bar."
