#!/usr/bin/env bash

input=$(cat)

MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')

# Icons (nerdfonts)
ICON_FOLDER=" " # U+F413
ICON_FOLDER_CHILD=" " # U+EF81
ICON_FOLDER_OUTSIDE="󰷌 " # U+F0DCC
ICON_GIT_BRANCH=" " # U+F418
ICON_GIT_MAIN=" " # U+F419
ICON_CONTEXT=" " # U+EDE8

# Directory display: project/current (or just project if same)
# Green if at project root, yellow otherwise
PROJECT_NAME=$(basename "$PROJECT_DIR")
CURRENT_NAME=$(basename "$CURRENT_DIR")
if [ "$PROJECT_DIR" = "$CURRENT_DIR" ]; then
  DIR_DISPLAY="\033[32m${ICON_FOLDER}${PROJECT_NAME}\033[0m"
elif [[ "$CURRENT_DIR" == "$PROJECT_DIR"/* ]]; then
  DIR_DISPLAY="\033[33m${ICON_FOLDER_CHILD}${PROJECT_NAME}/${CURRENT_NAME}\033[0m"
else
  DIR_DISPLAY="\033[35m${ICON_FOLDER_OUTSIDE}${CURRENT_NAME}\033[0m"
fi

# Git branch: magenta for main, cyan for others
GIT_BRANCH=""
if git rev-parse &>/dev/null; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
      GIT_BRANCH=" | \033[35m${ICON_GIT_MAIN}$BRANCH\033[0m"
    else
      GIT_BRANCH=" | \033[36m${ICON_GIT_BRANCH}$BRANCH\033[0m"
    fi
  else
    COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null)
    if [ -n "$COMMIT_HASH" ]; then
      GIT_BRANCH=" | \033[36m${ICON_GIT_BRANCH}HEAD ($COMMIT_HASH)\033[0m"
    fi
  fi
fi

# Context window from JSON
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
USED_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
# Handle null (before first API call)
[ "$USED_PCT" = "null" ] && USED_PCT=0

# Calculate used tokens from raw counts (more accurate than used_percentage)
USED_TOKENS=$(echo "$input" | jq -r '
  .context_window.current_usage // { input_tokens: 0, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 } |
  (.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens)
')

# Braille bar: each char = 200K tokens
# Levels: ⠐(0) ⢀(1+) ⣀(25K+) ⣄(50K+) ⣤(75K+) ⣦(100K+) ⣶(125K+) ⣷(150K+) ⣿(175K+)
BRAILLE=(⠐ ⢀ ⣀ ⣄ ⣤ ⣦ ⣶ ⣷ ⣿)
NUM_CHUNKS=$(( CONTEXT_SIZE / 200000 ))
BAR=""
for (( i = 0; i < NUM_CHUNKS; i++ )); do
  chunk_start=$(( i * 200000 ))
  chunk_end=$(( (i + 1) * 200000 ))

  if [ "$USED_TOKENS" -le "$chunk_start" ]; then
    BAR+="${BRAILLE[0]}"
  elif [ "$USED_TOKENS" -ge "$chunk_end" ]; then
    BAR+="${BRAILLE[8]}"
  else
    t=$(( USED_TOKENS - chunk_start ))
    # Map to braille level: 0=0, 1+=1, 25000+=2, ..., 175000+=8
    if   (( t >= 175000 )); then BAR+="${BRAILLE[8]}"
    elif (( t >= 150000 )); then BAR+="${BRAILLE[7]}"
    elif (( t >= 125000 )); then BAR+="${BRAILLE[6]}"
    elif (( t >= 100000 )); then BAR+="${BRAILLE[5]}"
    elif (( t >= 75000  )); then BAR+="${BRAILLE[4]}"
    elif (( t >= 50000  )); then BAR+="${BRAILLE[3]}"
    elif (( t >= 25000  )); then BAR+="${BRAILLE[2]}"
    elif (( t >= 1      )); then BAR+="${BRAILLE[1]}"
    else                         BAR+="${BRAILLE[0]}"
    fi
  fi
done

# Format token counts (e.g., 100K, 1M)
fmt() {
  local n=$1
  if (( n >= 1000000 )); then
    echo "$(( n / 1000000 ))M"
  elif (( n >= 1000 )); then
    echo "$(( n / 1000 ))K"
  else
    echo "$n"
  fi
}

USED_DISPLAY=$(fmt "$USED_TOKENS")
MAX_DISPLAY=$(fmt "$CONTEXT_SIZE")

# Context color by usage percentage
if (( USED_PCT >= 90 )); then
  CTX_COLOR="\033[31m"
elif (( USED_PCT >= 70 )); then
  CTX_COLOR="\033[33m"
else
  CTX_COLOR="\033[32m"
fi
RESET="\033[0m"

echo -e "󰚩 ${MODEL_DISPLAY} | ${DIR_DISPLAY}${GIT_BRANCH} | ${CTX_COLOR}${ICON_CONTEXT}${BAR} ${USED_DISPLAY}/${MAX_DISPLAY}${RESET}"
