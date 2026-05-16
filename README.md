# claude-bar

**[English](#english) · [中文](#中文)**

[![npm version](https://img.shields.io/npm/v/claude-bar)](https://www.npmjs.com/package/claude-bar)
[![license](https://img.shields.io/github/license/xuyiwenak/claude-bar)](LICENSE)

---

## English

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

### Requirements

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

### Installation

**Option A — npx (recommended, no install required)**
```bash
npx claude-bar
```

**Option B — Global npm install**
```bash
npm install -g claude-bar
claude-bar
```

**Option C — Clone and run**
```bash
git clone https://github.com/xuyiwenak/claude-bar.git
cd claude-bar && bash install.sh
```

Restart Claude Code after installing to see the status bar.

### What the installer does

1. Copies `statusline-command.sh` to `~/.claude/statusline-command.sh`
2. Patches `~/.claude/settings.json` (your existing settings are preserved):

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /Users/yourname/.claude/statusline-command.sh"
  }
}
```

A backup is saved as `settings.json.claude-bar_backup`.

### How it works

Claude Code calls the statusline command on every turn, passing a JSON blob via stdin. `claude-bar` reads three data sources:

**1. Context window % (real-time)**
Read directly from the Claude Code statusline JSON — same source as `/usage`, always accurate.

**2. Last interaction tokens (`↩`)**
Reads the most recent assistant message from the current project's JSONL session file at `~/.claude/projects/<slug>/<session>.jsonl`. Sums all token fields from the last API response.

**3. Today's total tokens (`∑`)**
Scans all project JSONL files under `~/.claude/projects/`, filters by local date (timezone-aware), and deduplicates by `message.id` to avoid double-counting.

> **Note:** Token counts include cache tokens and are approximate. They will not exactly match Anthropic's billing figures.

### Updating

```bash
npx claude-bar          # always fetches the latest from npm
```

### Uninstalling

```bash
npx claude-bar uninstall
```

Removes `~/.claude/statusline-command.sh` and the `statusLine` key from `~/.claude/settings.json`.

### Customization

The script lives at `~/.claude/statusline-command.sh` — edit it directly, no reinstall needed.

**Change bar width** (default: 10 segments):
```bash
for i in $(seq 1 10); do   # change 10 to any number
```

**Remove a segment** — delete its variable from the last `printf` line:
```bash
printf '%s  %s%s%s' "$model" "$short_cwd" "$ctx_part" "$last_tok"
```

### Troubleshooting

| Problem | Fix |
|---------|-----|
| Status bar not appearing | Quit Claude Code completely and reopen (not just a new session) |
| `jq: command not found` | `brew install jq` (macOS) or `sudo apt install jq` (Linux) |
| `↩` not showing | No sessions in current project yet — appears after your first interaction |
| `∑` not showing | No sessions recorded today (local time) yet |
| Numbers look inflated | Cache tokens are included; Anthropic bills them at a lower rate |

### License

MIT

---

## 中文

为 [Claude Code](https://claude.ai/code) 定制的状态栏插件，实时显示上下文用量、上次交互 token 消耗和今日 token 总量。

```
Sonnet 4.6  ~/myproject context[████░░░░░░ 40%] ↩12.3k ∑456k
```

| 字段 | 含义 |
|------|------|
| `Sonnet 4.6` | 当前使用的模型 |
| `~/myproject` | 当前工作目录 |
| `context[████░░░░░░ 40%]` | 上下文窗口用量（10 格进度条 + 百分比） |
| `↩12.3k` | **上次交互**消耗的 token 数 |
| `∑456k` | **今日**（本地时区）所有项目累计 token 总量 |

### 环境要求

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) ≥ 2.x
- `jq` — 解析状态栏 JSON 输入
- `python3` — 读取会话 JSONL 文件

**macOS：**
```bash
brew install jq
# python3 已预装
```

**Linux（Debian/Ubuntu）：**
```bash
sudo apt install jq python3
```

### 安装

**方式 A — npx（推荐，无需提前安装）**
```bash
npx claude-bar
```

**方式 B — 全局 npm 安装**
```bash
npm install -g claude-bar
claude-bar
```

**方式 C — 克隆后手动安装**
```bash
git clone https://github.com/xuyiwenak/claude-bar.git
cd claude-bar && bash install.sh
```

安装后重启 Claude Code（完全退出再重开）即可看到状态栏。

### 安装程序做了什么

1. 将 `statusline-command.sh` 复制到 `~/.claude/statusline-command.sh`
2. 向 `~/.claude/settings.json` 写入以下配置（已有配置不受影响）：

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /Users/yourname/.claude/statusline-command.sh"
  }
}
```

原始 `settings.json` 会备份为 `settings.json.claude-bar_backup`。

### 工作原理

Claude Code 在每次对话后调用状态栏命令，通过 stdin 传入 JSON 数据。`claude-bar` 从三个来源读取信息：

**1. 上下文用量百分比（实时）**
直接读取 Claude Code 状态栏 JSON，和 `/usage` 命令数据同源，始终准确。

**2. 上次交互 token（`↩`）**
读取当前项目最新的 JSONL 会话文件（位于 `~/.claude/projects/<项目名>/<会话id>.jsonl`），取最后一条 API 响应的 token 字段求和。

**3. 今日总 token（`∑`）**
扫描 `~/.claude/projects/` 下所有项目的 JSONL 文件，按本地时区日期过滤，并通过 `message.id` 去重（Claude Code 每条消息会写入多次，对应不同 content block）。

> **注意：** token 计数包含缓存字段，为近似值，不等于 Anthropic 账单金额（缓存 token 计费权重不同）。

### 更新

```bash
npx claude-bar   # 每次都从 npm 拉取最新版本
```

### 卸载

```bash
npx claude-bar uninstall
```

自动删除 `~/.claude/statusline-command.sh`，并从 `~/.claude/settings.json` 中移除 `statusLine` 配置。

### 自定义

安装后脚本在 `~/.claude/statusline-command.sh`，直接编辑即可，无需重新安装。

**修改进度条长度**（默认 10 格）：
```bash
for i in $(seq 1 10); do   # 改成 5、8、20 等任意数字
```

**去掉某个字段** — 从最后一行 `printf` 中删掉对应变量：
```bash
# 去掉今日总量：
printf '%s  %s%s%s' "$model" "$short_cwd" "$ctx_part" "$last_tok"
```

### 常见问题

| 问题 | 解决方法 |
|------|----------|
| 安装后状态栏没变化 | 完全退出 Claude Code 再重新打开（新建 session 不够） |
| `jq: command not found` | `brew install jq`（macOS）或 `sudo apt install jq`（Linux） |
| `↩` 不显示 | 当前项目还没有历史 session，完成第一次对话后出现 |
| `∑` 不显示 | 今日（本地时间）还没有记录，对话后即显示 |
| 数字偏大 | 包含了缓存 token，Anthropic 对缓存计费权重更低，所以会比账单高 |

### 开源协议

MIT

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=xuyiwenak/claude-bar&type=Date)](https://star-history.com/#xuyiwenak/claude-bar&Date)
