#!/usr/bin/env bash

input=$(cat)

R="\033[0m"
B="\033[1m"

fg()  { printf "\033[38;2;%s;%s;%sm" "$1" "$2" "$3"; }
bg()  { printf "\033[48;2;%s;%s;%sm" "$1" "$2" "$3"; }

C_HOST=$(fg 97 175 239)
C_MODEL=$(fg 198 120 221)
C_REPO=$(fg 229 192 123)
C_BRANCH=$(fg 152 195 121)
C_TIME=$(fg 92 99 112)
C_SEP=$(fg 126 132 150)

sep="$(printf '%b' " ${C_SEP}❯${R} ")"

json_get() {
  jq -r "$1 // empty" 2>/dev/null <<<"$input"
}

# Build a progress bar: fill=used%, width=10 chars
# Colors: green→yellow→red based on fill level
progress_bar() {
  local pct="$1"   # 0-100 float
  local label="$2"
  local tok="$3"   # optional token count string
  local width=10
  local filled=$(awk -v p="$pct" -v w="$width" 'BEGIN{printf "%.0f", p*w/100}')
  [ "$filled" -gt "$width" ] && filled=$width
  # show at least 1 block when there is any usage
  [ "$filled" -eq 0 ] && awk -v p="$pct" 'BEGIN{exit (p>0)?0:1}' && filled=1
  local empty=$((width - filled))

  local C_FILL
  if   [ "$filled" -ge 9 ]; then C_FILL=$(fg 224 108 117)
  elif [ "$filled" -ge 7 ]; then C_FILL=$(fg 229 192 123)
  else                            C_FILL=$(fg 152 195 121)
  fi

  local bar_filled="" bar_empty=""
  local i
  for ((i=0; i<filled; i++)); do bar_filled="${bar_filled}█"; done
  for ((i=0; i<empty;  i++)); do bar_empty="${bar_empty}░"; done

  local suffix=""
  [ -n "$tok" ] && suffix=" ${C_TOKEN}${B}${tok}${R}"

  printf '%b' "${C_TIME}${label}${R}${C_FILL}${B}${bar_filled}${R}${C_TIME}${bar_empty}$(printf '%.0f' "$pct")%${R}${suffix}"
}

TOK_MAX=100000000   # fallback if rate_limits not yet available

# ── rate limit data ──────────────────────────────────────────
# Get context window usage percentage
ctx_pct=$(json_get '.context_window.used_percentage')

# Get weekly model quota usage percentage
model_quota_remaining=$(jq -r '
  def words(s): s | ascii_downcase | gsub("[^a-z0-9]"; " ") | split(" ") | map(select(length > 0));
  .model.display_name as $m | (words($m)) as $mw |
  .quota | to_entries |
  map(. + {score: (.key | gsub("[^a-z0-9]"; " ") | split(" ") | map(. as $x | select($mw | index($x))) | length)}) |
  sort_by(-.score) | .[0] | select(.score > 0) | .value.remaining_fraction
' 2>/dev/null <<<"$input")

if [ -n "$model_quota_remaining" ]; then
  # Calculate used percentage: (1 - remaining_fraction) * 100
  week_pct=$(awk -v rem="$model_quota_remaining" 'BEGIN{printf "%.1f", (1 - rem) * 100}')
else
  week_pct=""
fi

# ── token counts (cached 60s) ────────────────────────────────
C_TOKEN=$(fg 209 154 102)
CACHE_FILE="/tmp/.claude_token_total_cache"
now_s=$(date +%s)
tok_5h="" tok_7d="" tok_total=""

if [ -f "$CACHE_FILE" ]; then
  cache_ts=$(awk '{print $1; exit}' "$CACHE_FILE" 2>/dev/null)
  cache_vals=$(awk 'NR==1{$1=""; print substr($0,2)}' "$CACHE_FILE" 2>/dev/null)
  age=$((now_s - ${cache_ts:-0}))
fi

if [ -z "$cache_vals" ] || [ "${age:-999}" -gt 60 ]; then
  since_5h=$((now_s - 5*3600))
  since_7d=$((now_s - 7*86400))
  cache_vals=$(find ~/.claude/projects -name "*.jsonl" 2>/dev/null \
    | xargs cat 2>/dev/null \
    | jq -rn --argjson s5h "$since_5h" --argjson s7d "$since_7d" '
        def fmt(n):
          "\(n)" | [scan(".{1,3}(?=(?:.{3})*$)")] | join(",");
        [inputs | select(.message.usage != null) |
          {
            ts: (.timestamp | gsub("\\.[0-9]+Z$";"Z") | try fromdateiso8601 catch 0),
            t: ((.message.usage.input_tokens               // 0) +
                (.message.usage.output_tokens              // 0) +
                (.message.usage.cache_creation_input_tokens // 0) +
                (.message.usage.cache_read_input_tokens    // 0))
          }
        ] |
        {
          h5:  (map(select(.ts >= $s5h) | .t) | add // 0),
          d7:  (map(select(.ts >= $s7d) | .t) | add // 0),
          all: (map(.t) | add // 0)
        } |
        "\(fmt(.h5)) \(fmt(.d7)) \(fmt(.all)) \(.h5) \(.d7) \(.all)"
      ' 2>/dev/null)
  printf '%s %s\n' "$now_s" "${cache_vals:-0 0 0 0 0 0}" > "$CACHE_FILE"
fi

tok_5h=$(     printf '%s' "$cache_vals" | awk '{print $1}')
tok_7d=$(     printf '%s' "$cache_vals" | awk '{print $2}')
tok_total=$(  printf '%s' "$cache_vals" | awk '{print $3}')
tok_5h_raw=$( printf '%s' "$cache_vals" | awk '{print $4}')
tok_7d_raw=$( printf '%s' "$cache_vals" | awk '{print $5}')
tok_raw=$(    printf '%s' "$cache_vals" | awk '{print $6}')

# ── host / model / git ───────────────────────────────────────
host="${USER}@$(hostname -s)"
model=$(json_get '.model.display_name // .model.id')
case "$model" in
  Claude\ *) model="${model#Claude }" ;;
esac

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

if [ -n "$repo_owner" ] && [ -n "$repo_name" ]; then
  repo="${repo_owner}/${repo_name}"
elif [ -n "$repo_name" ]; then
  repo="$repo_name"
else
  repo=$(basename "$cwd")
fi

# ── assemble parts ───────────────────────────────────────────
parts=()
parts+=("$(printf '%b' "${C_HOST}${B}${host}${R}")")
[ -n "$model" ] && parts+=("$(printf '%b' "${C_MODEL}${B}${model}${R}")")

repo_part="$(printf '%b' "${C_REPO}${B}${repo}${R}")"
[ -n "$branch" ] && repo_part="${repo_part} $(printf '%b' "${C_BRANCH}${B}${branch}${R}")"
parts+=("$repo_part")

[ -n "$ctx_pct" ] && parts+=("$(progress_bar "$ctx_pct" "5h:" "")")
[ -n "$week_pct" ] && parts+=("$(progress_bar "$week_pct" "7d:" "")")
[ -n "$week_pct" ] && parts+=("$(progress_bar "$week_pct" "🅰:" "")")

parts+=("$(printf '%b' "${C_TIME}$(date +%H:%M)${R}")")

out=""
for part in "${parts[@]}"; do
  out="${out:+${out}${sep}}${part}"
done

printf '%b\n' "$out"
