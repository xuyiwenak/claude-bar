#!/usr/bin/env bash
# claude_bar installer
# Copies statusline-command.sh to ~/.claude/ and patches ~/.claude/settings.json

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
TARGET="$CLAUDE_DIR/statusline-command.sh"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "==> Installing claude_bar..."

# ── 1. Dependency check ────────────────────────────────────────────────────
for cmd in jq python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not installed." >&2
    echo "  macOS:  brew install $cmd" >&2
    echo "  Linux:  sudo apt install $cmd  (or equivalent)" >&2
    exit 1
  fi
done

# ── 2. Copy script ─────────────────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR"
cp "$REPO_DIR/statusline-command.sh" "$TARGET"
chmod +x "$TARGET"
echo "    Copied statusline-command.sh -> $TARGET"

# ── 3. Patch settings.json ─────────────────────────────────────────────────
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

# Back up before patching
cp "$SETTINGS" "${SETTINGS}.claude_bar_backup"

# Inject statusLine config (preserves all existing keys)
python3 - "$SETTINGS" "$TARGET" << 'PYEOF'
import json, sys

settings_path = sys.argv[1]
script_path   = sys.argv[2]

with open(settings_path) as f:
    settings = json.load(f)

settings["statusLine"] = {
    "type": "command",
    "command": f"bash {script_path}"
}

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(f"    Patched {settings_path}")
PYEOF

echo ""
echo "✓ Done! Restart Claude Code (or open a new session) to see the status bar."
echo ""
echo "  Preview:"
echo '  Sonnet 4.6  ~/myproject context[████░░░░░░ 40%] ↩12.3k ∑456k'
echo ""
echo "  To uninstall, run:  bash uninstall.sh"
echo "  To update, run:     bash install.sh  (re-run anytime)"
