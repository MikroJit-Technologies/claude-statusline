<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:1c1917,50:2d1f17,100:cc785c&height=200&section=header&text=claude-statusline&fontSize=48&fontColor=ffffff&animation=fadeIn&fontAlignY=40&desc=Statusline%20for%20Claude%20Code%20CLI&descAlignY=62&descSize=20&descColor=e8c4a8" width="100%" />

<br/>

[![CI](https://img.shields.io/github/actions/workflow/status/MikroJit-Technologies/claude-statusline/test.yml?style=flat-square&label=CI&logo=githubactions&logoColor=white)](https://github.com/MikroJit-Technologies/claude-statusline/actions)
[![Shell](https://img.shields.io/badge/Shell-bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey?style=flat-square)](https://github.com/MikroJit-Technologies/claude-statusline)
[![License](https://img.shields.io/github/license/MikroJit-Technologies/claude-statusline?style=flat-square&color=yellow)](LICENSE)
[![Stars](https://img.shields.io/github/stars/MikroJit-Technologies/claude-statusline?style=flat-square&color=cc785c)](https://github.com/MikroJit-Technologies/claude-statusline/stargazers)

</div>

Statusline script for [Claude Code](https://claude.ai/code) that shows model, repo/branch, rate limits, and context window — rendered inline in the terminal on every turn.

---

## Preview

```
thiraphatsrichit@MacBook-Air ❯ Sonnet 4.6 ❯ 12MICKY/claude-config main ❯ 5h:█░░░░░░░░░11% ❯ 7d:█░░░░░░░░░12% ❯ 🅰:██████░░░░63% ❯ 03:05
```

<table>
<tr>
<th>Segment</th>
<th>Source</th>
<th>Description</th>
</tr>
<tr><td><code>user@host</code></td><td>shell</td><td>Current user and hostname (trimmed to 2 parts)</td></tr>
<tr><td>Model</td><td><code>.model.display_name</code></td><td>Active Claude model, "Claude " prefix stripped</td></tr>
<tr><td><code>owner/repo branch</code></td><td>git + JSON</td><td>Repo name, owner, and current branch</td></tr>
<tr><td><code>5h:███░░░░░░░</code></td><td><code>.rate_limits.five_hour</code></td><td>5-hour rate limit used % · green→yellow→red</td></tr>
<tr><td><code>7d:███░░░░░░░</code></td><td><code>.rate_limits.seven_day</code></td><td>7-day rate limit used %</td></tr>
<tr><td><code>🅰:███░░░░░░░</code></td><td><code>.context_window</code></td><td>Context window used % for this session</td></tr>
<tr><td><code>HH:MM</code></td><td>system</td><td>Current local time</td></tr>
</table>

> `5h:` and `7d:` fall back to `.quota` if `rate_limits` is absent in the JSON payload.

---

## Install

```bash
git clone https://github.com/MikroJit-Technologies/claude-statusline
cd claude-statusline
./install.sh
```

`install.sh` copies `statusline-command.sh` to `~/.claude/` and prints the settings snippet.

Then add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

Reload Claude Code — the statusline appears immediately.

---

## Requirements

| Tool | Why |
|---|---|
| `bash` 4+ | array syntax, `(( ))` arithmetic |
| `jq` | JSON parsing from Claude Code's stdin payload |
| `git` | branch detection fallback when JSON omits it |
| `awk` | progress bar math and token cache formatting |

Install on macOS: `brew install jq`  
Install on Ubuntu/Debian: `apt install jq`

---

## How it works

Claude Code pipes a JSON object to the script on every turn via stdin. The script reads:

```
stdin JSON → parse fields → build ANSI segments → print one line
```

Token totals (5h / 7d / all-time) are computed from `~/.claude/projects/**/*.jsonl` and cached for 60 seconds in `/tmp/.claude_token_total_cache` to avoid re-scanning on every turn.

---

## Color scheme

| Color | Hex | Used for |
|---|---|---|
| Blue | `#61AFEF` | hostname |
| Purple | `#C678DD` | model name |
| Yellow | `#E5C07B` | repo name |
| Green | `#98C379` | branch · bar fill (low) |
| Orange | `#E5C07B` | bar fill (medium) |
| Red | `#E06C75` | bar fill (high ≥ 90%) |
| Grey | `#5C6370` | separators · labels · time |

---

## License

MIT © 2026 [MikroJit Technologies](https://github.com/MikroJit-Technologies)

<div align="center">
<img src="https://capsule-render.vercel.app/api?type=waving&color=0:cc785c,100:1c1917&height=100&section=footer" width="100%" />
</div>
