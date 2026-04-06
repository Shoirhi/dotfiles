#!/bin/bash

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir' | sed "s|$HOME|~|g")
model=$(echo "$input" | jq -r '.model.display_name')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
transcript=$(echo "$input" | jq -r '.transcript_path')
todo_count=$([ -f "$transcript" ] && grep -c '"type":"todo"' "$transcript" 2>/dev/null || echo 0)
time_now=$(date +%H:%M)

# Truncate directory to last 4 segments (like starship truncation_length=4)
seg_count=$(echo "$cwd" | tr '/' '\n' | wc -l | tr -d ' ')
if [ "$seg_count" -gt 4 ]; then
  cwd=".../"$(echo "$cwd" | rev | cut -d'/' -f1-4 | rev)
fi

# Git info
cd "$(echo "$input" | jq -r '.workspace.current_dir')" 2>/dev/null
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')
git_status_str=''
if [ -n "$branch" ]; then
  porcelain=$(git status --porcelain 2>/dev/null)
  if [ -n "$porcelain" ]; then
    local modified=0 staged=0 untracked=0
    while IFS= read -r line; do
      case "${line:0:2}" in
        '??') untracked=$((untracked + 1)) ;;
        ' M'|'MM'|' D') modified=$((modified + 1)) ;;
        'M '|'A '|'D '|'R ') staged=$((staged + 1)) ;;
      esac
    done <<< "$porcelain"
    [ "$staged" -gt 0 ] && git_status_str="${git_status_str} +${staged}"
    [ "$modified" -gt 0 ] && git_status_str="${git_status_str} ~${modified}"
    [ "$untracked" -gt 0 ] && git_status_str="${git_status_str} ?${untracked}"
  fi
fi

# Catppuccin Frappe palette (matching starship)
BLUE='\033[1;38;2;140;170;238m'     # #8caaee - directory
MAUVE='\033[1;38;2;202;158;230m'    # #ca9ee6 - git branch
RED='\033[1;38;2;231;130;132m'      # #e78284 - git status
YELLOW='\033[1;38;2;229;200;144m'   # #e5c890 - context/duration
OVERLAY1='\033[1;38;2;131;139;167m' # #838ba7 - time, model
TEAL='\033[1;38;2;129;200;190m'     # #81c8be - todos
GREEN='\033[1;38;2;166;209;137m'    # #a6d189 - context ok
RST='\033[0m'

# Format: directory  git_branch git_status | model ctx time todos
printf "${BLUE}${cwd}${RST}"
[ -n "$branch" ] && printf " ${MAUVE}${branch}${RST}"
[ -n "$git_status_str" ] && printf " ${RED}${git_status_str# }${RST}"
printf " ${OVERLAY1}${model}${RST}"
if [ -n "$remaining" ]; then
  if [ "$remaining" -gt 50 ] 2>/dev/null; then
    printf " ${GREEN}ctx:${remaining}%%${RST}"
  else
    printf " ${YELLOW}ctx:${remaining}%%${RST}"
  fi
fi
printf " ${OVERLAY1}${time_now}${RST}"
[ "$todo_count" -gt 0 ] && printf " ${TEAL}todos:${todo_count}${RST}"
echo
