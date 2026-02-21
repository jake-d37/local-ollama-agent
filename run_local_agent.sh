#!/bin/bash

# ─────────────────────────────────────────────
#  Local Ollama Agent Runner
# ─────────────────────────────────────────────

# ---- Default values ----
MODEL="mistral"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="outputs/ollama_output_$TIMESTAMP.txt"

# ---- Colors & Styles ----
RESET="\033[0m"
BOLD="\033[1m"

# Palette
C_BORDER="\033[38;5;240m"
C_TITLE="\033[38;5;153m"
C_LABEL="\033[38;5;245m"
C_USER="\033[38;5;222m"
C_ASSISTANT="\033[38;5;150m"
C_DIM="\033[38;5;238m"
C_ACCENT="\033[38;5;117m"
C_WARN="\033[38;5;203m"

# ---- Box drawing ----
TL="╭" TR="╮" BL="╰" BR="╯" H="─" V="│"

# ---- Helpers ----
repeat_char() { printf '%0.s'"$1" $(seq 1 "$2"); }
get_term_width() { tput cols 2>/dev/null || echo 80; }

print_line() {
  local width="${1:-60}"
  printf "${C_BORDER}%s%s%s${RESET}\n" "$TL" "$(repeat_char "$H" $((width - 2)))" "$TR"
}

print_bottom() {
  local width="${1:-60}"
  printf "${C_BORDER}%s%s%s${RESET}\n" "$BL" "$(repeat_char "$H" $((width - 2)))" "$BR"
}

# ---- Parse Arguments ----
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --model)  MODEL="$2";       shift 2 ;;
    --output) OUTPUT_FILE="$2"; shift 2 ;;
    *)
      printf "${C_WARN}✗ Unknown parameter: %s${RESET}\n" "$1"
      exit 1
      ;;
  esac
done

# ---- Ensure output directory exists ----
mkdir -p "$(dirname "$OUTPUT_FILE")"

# ---- Start Log File ----
printf "Model: %s\nStarted: %s\n\n" "$MODEL" "$(date)" > "$OUTPUT_FILE"

# ---- Draw Header ----
clear
W=$(get_term_width)
[[ $W -gt 88 ]] && W=88

printf "\n"
print_line "$W"
printf "${C_BORDER}${V}${RESET}"
printf "${C_TITLE}${BOLD}  ◈  LOCAL OLLAMA AGENT$(printf '%*s' $((W - 24)) '')${RESET}"
printf "${C_BORDER}${V}${RESET}\n"
printf "${C_BORDER}${V}${RESET}"
printf "${C_LABEL}     model  ${RESET}${C_ACCENT}${MODEL}$(printf '%*s' $((W - 14 - ${#MODEL})) '')${RESET}"
printf "${C_BORDER}${V}${RESET}\n"
printf "${C_BORDER}${V}${RESET}"
printf "${C_LABEL}       log  ${RESET}${C_DIM}${OUTPUT_FILE}$(printf '%*s' $((W - 14 - ${#OUTPUT_FILE})) '')${RESET}"
printf "${C_BORDER}${V}${RESET}\n"
print_bottom "$W"

printf "\n${C_DIM}  Paste or type your message."
printf " Press ${RESET}${C_ACCENT}Enter${RESET}${C_DIM} twice to send."
printf " Type ${RESET}${C_WARN}exit${RESET}${C_DIM} to quit.${RESET}\n\n"

# ---- Readline bindings for word navigation ----
# These map the escape sequences macOS sends for option+arrow
bind '"\e[1;3C": forward-word'  2>/dev/null   # option+right
bind '"\e[1;3D": backward-word' 2>/dev/null   # option+left
bind '"\ef": forward-word'      2>/dev/null   # alt+f fallback
bind '"\eb": backward-word'     2>/dev/null   # alt+b fallback

# ---- Conversation history (JSON array) ----
MESSAGES="[]"

# ---- Spinner ----
spinner() {
  local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  local i=0
  while true; do
    printf "\r  ${C_ACCENT}${frames[$i]}${RESET}${C_DIM}  thinking...${RESET}"
    i=$(( (i + 1) % ${#frames[@]} ))
    sleep 0.08
  done
}

# ─────────────────────────────────────────────
#  Main loop
# ─────────────────────────────────────────────
while true; do

  # ── Multiline user input with readline editing ───────────────────
  # read -e enables readline: arrow keys, ctrl+a/e, option+arrow, etc.
  # Each line is edited independently; blank line submits.
  USER_PROMPT=""
  FIRST_LINE=true

  while true; do
    if [[ "$FIRST_LINE" == true ]]; then
      PROMPT_STR="$(printf "${C_USER}${BOLD}  you  ${RESET}${C_BORDER}▸${RESET} ")"
      FIRST_LINE=false
    else
      PROMPT_STR="$(printf "         ${C_DIM}·${RESET} ")"
    fi

    IFS= read -r -e -p "$PROMPT_STR" input_line
    READ_STATUS=$?

    # EOF (ctrl+d) or blank line = submit
    if [[ $READ_STATUS -ne 0 || -z "$input_line" ]]; then
      break
    fi

    # Add to readline history so up-arrow recalls previous lines
    history -s "$input_line"

    [[ -n "$USER_PROMPT" ]] && USER_PROMPT+=$'\n'
    USER_PROMPT+="$input_line"
  done

  # ── Check for exit ───────────────────────────────────────────────
  if [[ "$USER_PROMPT" == "exit" ]]; then
    printf "\n${C_DIM}  $(repeat_char "╌" $((W - 4)))${RESET}\n"
    printf "  ${C_LABEL}Session saved to ${RESET}${C_ACCENT}%s${RESET}\n\n" "$OUTPUT_FILE"
    break
  fi

  [[ -z "$USER_PROMPT" ]] && continue

  # Append user message to history
  MESSAGES=$(echo "$MESSAGES" | jq --arg content "$USER_PROMPT" \
    '. + [{"role":"user","content":$content}]')
  printf "\nYou:\n%s\n\nAssistant:\n" "$USER_PROMPT" >> "$OUTPUT_FILE"

  # Build request body
  REQUEST=$(jq -n --arg model "$MODEL" --argjson messages "$MESSAGES" \
    '{"model":$model,"messages":$messages,"stream":true}')

  # ── Start spinner ────────────────────────────────────────────────
  spinner &
  SPINNER_PID=$!

  # ── Stream and accumulate full response ──────────────────────────
  TMPFILE=$(mktemp)

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    content=$(echo "$line" | jq -r '.message.content // empty')
    done_flag=$(echo "$line" | jq -r '.done // false')
    [[ -n "$content" ]] && printf '%s' "$content" >> "$TMPFILE"
    [[ "$done_flag" == "true" ]] && break
  done < <(curl -s -X POST http://localhost:11434/api/chat \
    -H "Content-Type: application/json" \
    -d "$REQUEST")

  FULL_RESPONSE=$(cat "$TMPFILE")
  rm -f "$TMPFILE"

  # Kill spinner, clear line
  kill "$SPINNER_PID" 2>/dev/null
  wait "$SPINNER_PID" 2>/dev/null
  printf "\r\033[K"

  # ── Print response ───────────────────────────────────────────────
  printf "\n  ${C_ASSISTANT}${BOLD}agent${RESET}${C_BORDER} ▸${RESET}\n\n"
  printf '    %s\n' "$FULL_RESPONSE"

  # ── Divider ──────────────────────────────────────────────────────
  printf "\n${C_DIM}  $(repeat_char "╌" $((W - 4)))${RESET}\n\n"

  # Append to history and log
  MESSAGES=$(echo "$MESSAGES" | jq --arg content "$FULL_RESPONSE" \
    '. + [{"role":"assistant","content":$content}]')
  printf '%s\n' "$FULL_RESPONSE" >> "$OUTPUT_FILE"

done