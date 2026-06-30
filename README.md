<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0d1117,50:1a2332,100:388bfd&height=180&section=header&text=claude-statusline&fontSize=42&fontColor=ffffff&animation=fadeIn&fontAlignY=40&desc=Claude%20Code%20statusline%20layout&descAlignY=62&descSize=18&descColor=8b949e" width="100%" />

</div>

Statusline script for [Claude Code](https://claude.ai/code) that shows model, repo/branch, context window usage, weekly quota, and token totals — rendered inline in the terminal.

## Preview

```
thiraphat@mac ❯ Sonnet 4.6 ❯ 12MICKY/claude-statusline main ❯ ctx░░░░░░░░░░0% ❯ 23:41
```

## What it shows

| Segment | Description |
|---|---|
| `user@host` | Current user and hostname |
| Model | Claude model display name |
| `owner/repo branch` | Git repo and current branch |
| Context bar | Context window used % (green → yellow → red) |
| Weekly bar | Weekly model quota used % |
| Token counts | 5h / 7d / all-time token totals (cached 60s) |
| Time | Current time `HH:MM` |

## Install

```bash
git clone https://github.com/MikroJit-Technologies/claude-statusline
cd claude-statusline
./install.sh
```

Then add to `~/.claude/settings.json`:

```json
{
  "statusCommand": "~/.claude/statusline-command.sh"
}
```

## Requirements

- `jq` — JSON parsing
- `git` — branch detection
- bash 4+

## License

MIT © 2026 [MikroJit Technologies](https://github.com/MikroJit-Technologies)
