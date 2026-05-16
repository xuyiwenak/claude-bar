#!/usr/bin/env bash
# claude_bar — Claude Code custom status line
# Shows: model · cwd · context window bar · last interaction tokens · today total tokens
#
# Data sources:
#   - context %    : Claude Code statusline JSON (real-time)
#   - last ↩ tokens: most recent assistant message in current project's JSONL session file
#   - today ∑ tokens: all project JSONL files, local-timezone date filter, deduped by message.id

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "?"')
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# ── Context window progress bar (10 segments) ──────────────────────────────
if [ -n "$used_pct" ]; then
  filled=$(echo "$used_pct" | awk '{printf "%d", int($1 / 10 + 0.5)}')
  bar=""
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then bar="${bar}█"; else bar="${bar}░"; fi
  done
  used_int=$(printf '%.0f' "$used_pct")
  ctx_part=" context[${bar} ${used_int}%]"
else
  ctx_part=""
fi

# ── Shorten cwd ────────────────────────────────────────────────────────────
home_dir="$HOME"
short_cwd="${cwd/#$home_dir/~}"

# ── Last interaction token count ───────────────────────────────────────────
last_tok=""
project_slug=$(echo "$cwd" | sed 's|/|-|g')
project_dir="$home_dir/.claude/projects/$project_slug"

if [ -d "$project_dir" ]; then
  latest_jsonl=$(ls -t "$project_dir"/*.jsonl 2>/dev/null | head -1)
  if [ -n "$latest_jsonl" ]; then
    last_usage=$(python3 -c "
import json
lines = open('$latest_jsonl').readlines()
for line in reversed(lines):
    try:
        obj = json.loads(line)
        usage = obj.get('message', {}).get('usage', {})
        if usage and 'output_tokens' in usage:
            total = (usage.get('input_tokens', 0) + usage.get('output_tokens', 0) +
                     usage.get('cache_creation_input_tokens', 0) + usage.get('cache_read_input_tokens', 0))
            if total > 0:
                print(total)
                break
    except:
        pass
" 2>/dev/null)
    if [ -n "$last_usage" ]; then
      if [ "$last_usage" -ge 1000 ] 2>/dev/null; then
        last_tok_fmt=$(echo "$last_usage" | awk '{printf "%.1fk", $1/1000}')
      else
        last_tok_fmt="$last_usage"
      fi
      last_tok=" ↩${last_tok_fmt}"
    fi
  fi
fi

# ── Today total tokens (all projects, local timezone, deduped) ─────────────
today_tok=""
jsonl_list=$(find "$home_dir/.claude/projects" -name "*.jsonl" 2>/dev/null | tr '\n' ':')
if [ -n "$jsonl_list" ]; then
  today_total=$(python3 - "$jsonl_list" << 'PYEOF'
import json, sys
from datetime import datetime, timezone

paths = sys.argv[1].split(':')
today_local = datetime.now(timezone.utc).astimezone().date()
seen = set()
total = 0

for path in paths:
    path = path.strip()
    if not path:
        continue
    try:
        for line in open(path):
            obj = json.loads(line)
            msg = obj.get('message', {})
            mid = msg.get('id', '')
            usage = msg.get('usage', {})
            if not (usage and 'output_tokens' in usage):
                continue
            if mid and mid in seen:
                continue
            if mid:
                seen.add(mid)
            ts = obj.get('timestamp', '')
            if not isinstance(ts, str) or not ts:
                continue
            try:
                dt = datetime.fromisoformat(ts.replace('Z', '+00:00'))
            except Exception:
                continue
            if dt.astimezone().date() != today_local:
                continue
            total += (usage.get('input_tokens', 0) + usage.get('output_tokens', 0) +
                      usage.get('cache_creation_input_tokens', 0) + usage.get('cache_read_input_tokens', 0))
    except Exception:
        pass

if total > 0:
    if total >= 1000000:
        print(f'{total/1000000:.1f}M')
    elif total >= 1000:
        print(f'{total/1000:.1f}k')
    else:
        print(total)
PYEOF
  )
  if [ -n "$today_total" ]; then
    today_tok=" ∑${today_total}"
  fi
fi

printf '%s  %s%s%s%s' "$model" "$short_cwd" "$ctx_part" "$last_tok" "$today_tok"
