# claude_bar

A custom status line for [Claude Code](https://claude.ai/code) that shows real-time context usage, per-interaction token cost, and today's total token consumption — all at a glance.

```
Sonnet 4.6  ~/myproject context[████░░░░░░ 40%] ↩12.3k ∑456k
```

| Segment | Meaning |
|---------|---------|
| `Sonnet 4.6` | Active model |
| `~/myproject` | Current working directory |
| `context[████░░░░░░ 40%]` | Context window usage (10-segment bar + %) |
| `↩12.3k` | Tokens consumed in the **last interaction** |
| `∑456k` | **Today's** total tokens across all projects (local timezone) |

---

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) ≥ 2.x
- `jq` — for parsing the statusline JSON input
- `python3` — for reading session JSONL files

**macOS:**
```bash
brew install jq
# python3 is pre-installed on macOS
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt install jq python3
```

---

## Installation

### Option A — npx (no install required, recommended)

```bash
npx claude_bar
```

That's it. npx downloads and runs the installer automatically. No `git clone` needed.

### Option B — Global install

```bash
npm install -g claude_bar
claude_bar
```

Useful if you want the `claude_bar` command always available to re-run or update.

### Option C — Clone and install

```bash
git clone https://github.com/xuyiwenak/claude_bar.git
cd claude_bar
bash install.sh
```

Then restart Claude Code (quit and reopen, or start a new session).

### What the installer does

1. Copies `statusline-command.sh` to `~/.claude/statusline-command.sh`
2. Adds the following to `~/.claude/settings.json` (preserving all your existing settings):

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /Users/yourname/.claude/statusline-command.sh"
  }
}
```

A backup of your original `settings.json` is saved as `settings.json.claude_bar_backup`.

---

## How it works

Claude Code calls the statusline command on every turn, passing a JSON blob via stdin. `claude_bar` reads three data sources:

### 1. Context window % (real-time)
Read directly from the Claude Code statusline JSON:
```json
{ "context_window": { "used_percentage": 40.2 } }
```
This is the same data shown by `/usage` — always accurate.

### 2. Last interaction tokens (`↩`)
Reads the most recent assistant message from the current project's JSONL session file at:
```
~/.claude/projects/<project-slug>/<session-id>.jsonl
```
Sums `input_tokens + output_tokens + cache_creation_input_tokens + cache_read_input_tokens` from the last API response.

### 3. Today's total tokens (`∑`)
Scans **all** project JSONL files under `~/.claude/projects/`, filters by **local date** (timezone-aware), and deduplicates by `message.id` to avoid double-counting (Claude Code writes each message to the JSONL multiple times — once per content block).

> **Note:** Token counts include cache tokens and are an approximation. They will not exactly match Anthropic's billing figures, which apply different weights to cached vs. non-cached tokens.

---

## Updating

```bash
npx claude_bar          # always fetches the latest version from npm
```

Or if installed globally:
```bash
npm update -g claude_bar
claude_bar
```

---

## Uninstalling

```bash
npx claude_bar uninstall
```

Or if installed globally:
```bash
claude_bar uninstall
```

This removes `~/.claude/statusline-command.sh` and strips the `statusLine` key from `~/.claude/settings.json`.

---

## Customization

The status bar is a plain bash script at `~/.claude/statusline-command.sh`. You can edit it directly after installation — no reinstall needed.

**Change the bar width** (default: 10 segments):
```bash
# In statusline-command.sh, change the loop bound:
for i in $(seq 1 10); do   # ← change 10 to 5, 8, 20, etc.
```

**Remove a segment** — just delete the corresponding `printf` variable from the last line:
```bash
# Remove today total:
printf '%s  %s%s%s' "$model" "$short_cwd" "$ctx_part" "$last_tok"
```

---

## Troubleshooting

**Status bar not appearing after install**
- Quit Claude Code completely and reopen it (not just a new session).
- Check that `~/.claude/settings.json` contains a `statusLine` key.

**`jq: command not found` error**
- Install jq: `brew install jq` (macOS) or `sudo apt install jq` (Linux).

**Token counts not showing (`↩` or `∑` missing)**
- These are read from `~/.claude/projects/`. If you have no prior sessions in the current project, `↩` won't appear until after your first interaction.
- `∑` won't appear if today (local time) has no recorded sessions yet.

**Numbers look wrong / inflated**
- Token counts include all cache fields. Anthropic bills cached tokens at a lower rate, so `∑` will be higher than your invoice.

---

## License

MIT
