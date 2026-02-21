#!/bin/bash

# ─────────────────────────────────────────────
#  Local Ollama Agent Runner
# ─────────────────────────────────────────────

RESOURCES_DIR="$(dirname "$0")/resources"
SCRIPTS_DIR="$(dirname "$0")/src"

# Default values
source "$RESOURCES_DIR/config.conf"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="outputs/ollama_output_$TIMESTAMP.txt"

source "$SCRIPTS_DIR/style.sh"
source "$SCRIPTS_DIR/print-helpers.sh"
source "$SCRIPTS_DIR/parse-args.sh"

mkdir -p "$(dirname "$OUTPUT_FILE")"

printf "Model: %s\nStarted: %s\n\n" "$MODEL" "$(date)" > "$OUTPUT_FILE"

draw_header

# ---- Conversation history (JSON array) ----
MESSAGES="[]"

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