#!/bin/bash

# ─────────────────────────────────────────────
#  Local Ollama Agent Runner
# ─────────────────────────────────────────────

# ---- Default values ----
MODEL="qwen2.5:14b"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="outputs/ollama_output_$TIMESTAMP.txt"

# ---- Colors & Styles ----
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Palette: deep slate bg aesthetic
C_BORDER="\033[38;5;240m"       # muted grey for borders
C_TITLE="\033[38;5;153m"        # soft sky blue
C_LABEL="\033[38;5;245m"        # mid grey
C_USER="\033[38;5;222m"         # warm amber
C_ASSISTANT="\033[38;5;150m"    # sage green
C_DIM="\033[38;5;238m"          # very dark grey
C_ACCENT="\033[38;5;117m"       # light blue accent
C_WARN="\033[38;5;203m"         # soft red

# ---- Box drawing ----
TL="╭" TR="╮" BL="╰" BR="╯" H="─" V="│"

# ---- Helpers ----
repeat_char() { printf '%0.s'"$1" $(seq 1 "$2"); }

print_line() {
  local width="${1:-60}"
  printf "${C_BORDER}%s%s%s${RESET}\n" "$TL" "$(repeat_char "$H" $((width - 2)))" "$TR"
}

print_bottom() {
  local width="${1:-60}"
  printf "${C_BORDER}%s%s%s${RESET}\n" "$BL" "$(repeat_char "$H" $((width - 2)))" "$BR"
}

print_row() {
  local content="$1"
  local width="${2:-60}"
  printf "${C_BORDER}${V}${RESET} %-*s ${C_BORDER}${V}${RESET}\n" $((width - 4)) "$content"
}

get_term_width() {
  tput cols 2>/dev/null || echo 80
}

# ---- Parse Arguments ----
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --model)
      MODEL="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
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
[[ $W -gt 80 ]] && W=80

printf "\n"
print_line "$W"
# Title row
printf "${C_BORDER}${V}${RESET}"
printf "${C_TITLE}${BOLD}  ◈  LOCAL OLLAMA AGENT$(printf '%*s' $((W - 24)) '')${RESET}"
printf "${C_BORDER}${V}${RESET}\n"
# Model row
printf "${C_BORDER}${V}${RESET}"
printf "${C_LABEL}     model  ${RESET}${C_ACCENT}${MODEL}$(printf '%*s' $((W - 14 - ${#MODEL})) '')${RESET}"
printf "${C_BORDER}${V}${RESET}\n"
# Log row
printf "${C_BORDER}${V}${RESET}"
printf "${C_LABEL}       log  ${RESET}${C_DIM}${OUTPUT_FILE}$(printf '%*s' $((W - 14 - ${#OUTPUT_FILE})) '')${RESET}"
printf "${C_BORDER}${V}${RESET}\n"
print_bottom "$W"

printf "\n${C_DIM}  Type your message and press Enter. Type ${RESET}${C_WARN}exit${RESET}${C_DIM} to quit.${RESET}\n\n"

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

# ---- Main Loop ----
while true; do
  # User prompt
  printf "${C_USER}${BOLD}  you  ${RESET}${C_BORDER}▸${RESET} "
  read -r USER_PROMPT

  if [[ "$USER_PROMPT" == "exit" ]]; then
    printf "\n${C_DIM}  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌${RESET}\n"
    printf "  ${C_LABEL}Session saved to ${RESET}${C_ACCENT}%s${RESET}\n\n" "$OUTPUT_FILE"
    break
  fi

  [[ -z "$USER_PROMPT" ]] && continue

  # Append user message to history
  MESSAGES=$(echo "$MESSAGES" | jq --arg content "$USER_PROMPT" '. + [{"role":"user","content":$content}]')
  printf "\nYou: %s\n\nAssistant:\n" "$USER_PROMPT" >> "$OUTPUT_FILE"

  # Build request body
  REQUEST=$(jq -n --arg model "$MODEL" --argjson messages "$MESSAGES" \
    '{"model":$model,"messages":$messages,"stream":true}')

  # Start spinner
  spinner &
  SPINNER_PID=$!

  # Stream response
  FULL_RESPONSE=""
  FIRST_TOKEN=true

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    content=$(echo "$line" | jq -r '.message.content // empty')
    done_flag=$(echo "$line" | jq -r '.done // false')

    if [[ -n "$content" ]]; then
      if [[ "$FIRST_TOKEN" == "true" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null
        printf "\r\033[K"
        printf "\n  ${C_ASSISTANT}${BOLD}agent${RESET}${C_BORDER} ▸${RESET} "
        FIRST_TOKEN=false
      fi
      printf "%s" "$content"
      FULL_RESPONSE+="$content"
    fi

    if [[ "$done_flag" == "true" ]]; then
      printf "\n"
      break
    fi
  done < <(curl -s -X POST http://localhost:11434/api/chat \
    -H "Content-Type: application/json" \
    -d "$REQUEST")

  # Kill spinner if no tokens arrived (e.g. error)
  kill "$SPINNER_PID" 2>/dev/null
  wait "$SPINNER_PID" 2>/dev/null

  # Divider between turns
  printf "\n${C_DIM}  $(repeat_char "╌" $((W - 4)))${RESET}\n\n"

  # Append assistant reply to history and log
  MESSAGES=$(echo "$MESSAGES" | jq --arg content "$FULL_RESPONSE" '. + [{"role":"assistant","content":$content}]')
  printf "%s\n" "$FULL_RESPONSE" >> "$OUTPUT_FILE"

done