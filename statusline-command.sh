#!/usr/bin/env bash
# Claude Code statusline — macOS + Linux + Windows (Git Bash / WSL) compatible

input=$(cat)

# ── ANSI helpers ──────────────────────────────────────────────
R="\033[0m"
B="\033[1m"
fg() { printf "\033[38;2;%s;%s;%sm" "$1" "$2" "$3"; }

C_HOST=$(fg 97 175 239)
C_MODEL=$(fg 198 120 221)
C_REPO=$(fg 229 192 123)
C_BRANCH=$(fg 152 195 121)
C_TIME=$(fg 92 99 112)
C_SEP=$(fg 126 132 150)
sep="$(printf '%b' " ${C_SEP}❯${R} ")"

# ── jq availability ───────────────────────────────────────────
HAS_JQ=0
command -v jq >/dev/null 2>&1 && HAS_JQ=1

json_get() {
  [ "$HAS_JQ" -eq 1 ] && jq -r "$1 // empty" 2>/dev/null <<<"$input" || echo ""
}

# ── Progress bar ──────────────────────────────────────────────
progress_bar() {
  local pct="$1" label="$2" width=10
  local filled empty C_FILL bar_filled="" bar_empty="" i
  filled=$(awk -v p="$pct" -v w="$width" \
    'BEGIN{f=int(p*w/100+0.5); if(f>w)f=w; if(f==0&&p>0)f=1; print f}')
  empty=$((width - filled))
  if   [ "$filled" -ge 9 ]; then C_FILL=$(fg 224 108 117)
  elif [ "$filled" -ge 7 ]; then C_FILL=$(fg 229 192 123)
  else                            C_FILL=$(fg 152 195 121)
  fi
  for ((i=0; i<filled; i++)); do bar_filled="${bar_filled}█"; done
  for ((i=0; i<empty;  i++)); do bar_empty="${bar_empty}░"; done
  printf '%b' "${C_TIME}${label}${R}${C_FILL}${B}${bar_filled}${R}${C_TIME}${bar_empty}$(printf '%.0f' "$pct")%${R}"
}

# ── Rate limits / context window ──────────────────────────────
ctx_pct=$(json_get '.context_window.used_percentage')
five_pct=$(json_get '.rate_limits.five_hour.used_percentage')
week_pct=$(json_get '.rate_limits.seven_day.used_percentage')

# fallback: derive from .quota if rate_limits absent
if [ -z "$week_pct" ] && [ "$HAS_JQ" -eq 1 ]; then
  quota_rem=$(jq -r '
    (.quota // {}) | to_entries |
    map(select(.value.remaining_fraction != null)) |
    .[0].value.remaining_fraction // empty
  ' 2>/dev/null <<<"$input")
  [ -n "$quota_rem" ] && \
    week_pct=$(awk -v r="$quota_rem" 'BEGIN{printf "%.0f", (1-r)*100}')
fi

# ── OS detection ─────────────────────────────────────────────
IS_WIN=0
case "$OSTYPE" in msys*|cygwin*|mingw*) IS_WIN=1 ;; esac

# ── Host (trim long machine names) ───────────────────────────
if [ "$IS_WIN" -eq 1 ]; then
  _hn="${COMPUTERNAME:-$(hostname 2>/dev/null || echo "windows")}"
  host="${USERNAME:-${USER:-user}}@${_hn}"
else
  _hn=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "localhost")
  _parts=$(printf '%s' "$_hn" | awk -F- '{print NF}')
  [ "$_parts" -gt 2 ] && _hn=$(printf '%s' "$_hn" | cut -d- -f1,2)
  host="${USER:-$(id -un)}@${_hn}"
fi

# ── Model ─────────────────────────────────────────────────────
model=$(json_get '.model.display_name // .model.id')
case "$model" in Claude\ *) model="${model#Claude }" ;; esac

# ── Repo / branch ─────────────────────────────────────────────
cwd=$(json_get '.workspace.current_dir')
[ -z "$cwd" ] && cwd="$PWD"

branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
[ -z "$branch" ] && branch=$(json_get '.workspace.git_worktree')
[ -z "$branch" ] && branch=$(json_get '.gitBranch')

repo_owner=$(json_get '.workspace.repo.owner')
repo_name=$(json_get '.workspace.repo.name')

if [ -z "$repo_name" ] && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
  repo_name=$(basename "$repo_root")
  remote_url=$(git -C "$cwd" remote get-url origin 2>/dev/null)
  if [ -n "$remote_url" ]; then
    parsed_owner=$(printf '%s\n' "$remote_url" \
      | sed -nE 's#^git@[^:]+:([^/]+)/.*#\1#p; s#^https?://[^/]+/([^/]+)/.*#\1#p' \
      | head -n 1)
    [ -n "$parsed_owner" ] && repo_owner="$parsed_owner"
  fi
fi

if [ -n "$repo_owner" ] && [ -n "$repo_name" ]; then repo="${repo_owner}/${repo_name}"
elif [ -n "$repo_name" ]; then repo="$repo_name"
else repo=$(basename "$cwd")
fi

# ── Assemble ──────────────────────────────────────────────────
parts=()
parts+=("$(printf '%b' "${C_HOST}${B}${host}${R}")")
[ -n "$model" ] && parts+=("$(printf '%b' "${C_MODEL}${B}${model}${R}")")

repo_part="$(printf '%b' "${C_REPO}${B}${repo}${R}")"
[ -n "$branch" ] && repo_part="${repo_part} $(printf '%b' "${C_BRANCH}${B}${branch}${R}")"
parts+=("$repo_part")

[ -n "$five_pct" ] && parts+=("$(progress_bar "$five_pct" "5h:")")
[ -n "$week_pct" ] && parts+=("$(progress_bar "$week_pct" "7d:")")
[ -n "$ctx_pct"  ] && parts+=("$(progress_bar "$ctx_pct"  "🅰:")")

parts+=("$(printf '%b' "${C_TIME}$(date +%H:%M)${R}")")

out=""
for part in "${parts[@]}"; do
  out="${out:+${out}${sep}}${part}"
done
printf '%b\n' "$out"
