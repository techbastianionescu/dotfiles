#!/usr/bin/env bash
# Claude Code status line script (Git Bash / bash)
# Reads JSON from stdin and outputs a formatted status line

# Ensure jq and git are findable when invoked non-interactively by Claude Code
export PATH="$HOME/.claude/bin:/c/Program Files/Git/mingw64/bin:/c/Program Files/Git/usr/bin:/c/Program Files/Git/bin:$PATH"

input=$(cat)

# ANSI color codes (use \033 for portability in non-interactive shells)
reset="\033[0m"
dim="\033[2m"
bold="\033[1m"
cyan="\033[36m"
yellow="\033[33m"
green="\033[32m"
magenta="\033[35m"
red="\033[31m"

# --- CWD (shortened) ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
# Normalise backslashes to forward slashes
cwd="${cwd//\\//}"
# Replace home directory with ~
home_unix="${USERPROFILE//\\//}"
if [ -n "$home_unix" ]; then
    cwd="${cwd/#$home_unix/\~}"
fi
# Shorten: keep first segment + last 2 if more than 4 parts
IFS='/' read -ra parts <<< "$cwd"
if [ "${#parts[@]}" -gt 4 ]; then
    cwd="${parts[0]}/.../${parts[-2]}/${parts[-1]}"
fi

# --- Git branch ---
git_branch=""
raw_cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
if [ -n "$raw_cwd" ]; then
    branch=$(git -C "$raw_cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
    [ -n "$branch" ] && git_branch="$branch"
fi

# --- Model name ---
model=$(echo "$input" | jq -r '.model.display_name // .model.id // ""')

# --- Context window usage ---
ctx_display=""
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
    used_int=$(printf '%.0f' "$used_pct")
    ctx_color="$green"
    [ "$used_int" -ge 75 ] && ctx_color="$red" || { [ "$used_int" -ge 50 ] && ctx_color="$yellow"; }
    ctx_display="${ctx_color}ctx:${used_int}%${reset}"
fi

# --- Rate limits ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rate_parts=()
if [ -n "$five_pct" ]; then
    five_int=$(printf '%.0f' "$five_pct")
    r_color="$green"
    [ "$five_int" -ge 75 ] && r_color="$red" || { [ "$five_int" -ge 50 ] && r_color="$yellow"; }
    rate_parts+=("${r_color}5h:${five_int}%${reset}")
fi
if [ -n "$week_pct" ]; then
    week_int=$(printf '%.0f' "$week_pct")
    r_color="$green"
    [ "$week_int" -ge 75 ] && r_color="$red" || { [ "$week_int" -ge 50 ] && r_color="$yellow"; }
    rate_parts+=("${r_color}7d:${week_int}%${reset}")
fi
rate_display=""
if [ "${#rate_parts[@]}" -gt 0 ]; then
    rate_display="${rate_parts[*]}"
fi

# --- Assemble line ---
sep="${dim} | ${reset}"

line="${cyan}${bold}${cwd}${reset}"

if [ -n "$git_branch" ]; then
    line+="${sep}${yellow}${git_branch}${reset}"
fi

line+="${sep}${magenta}${model}${reset}"

if [ -n "$ctx_display" ]; then
    line+="${sep}${ctx_display}"
fi

if [ -n "$rate_display" ]; then
    line+="${sep}${rate_display}"
fi

printf '%b' "$line"
