#!/bin/bash

# Default values
MODEL="qwen2.5:14b"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="outputs/ollama_output_$TIMESTAMP.txt"

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
      echo "Unknown parameter passed: $1"
      exit 1
      ;;
  esac
done

# ---- Ensure output directory exists ----
mkdir -p "$(dirname "$OUTPUT_FILE")"

# ---- Start Log File ----
printf "Model: %s\nStarted: %s\n\n" "$MODEL" "$(date)" > "$OUTPUT_FILE"

printf "\nRunning model: %s...\nType 'exit' to quit.\n\n" "$MODEL"

# ---- Conversation history (JSON array) ----
MESSAGES="[]"

while true; do
  printf "\nYou: "
  read -r USER_PROMPT

  if [[ "$USER_PROMPT" == "exit" ]]; then
    echo "Ending session..."
    break
  fi

  # Append user message to history
  MESSAGES=$(echo "$MESSAGES" | jq --arg content "$USER_PROMPT" '. + [{"role":"user","content":$content}]')

  printf "\nYou: %s\n\nAssistant:\n" "$USER_PROMPT" >> "$OUTPUT_FILE"
  printf "\nAssistant: "

  # Build request body
  REQUEST=$(jq -n --arg model "$MODEL" --argjson messages "$MESSAGES" \
    '{"model":$model,"messages":$messages,"stream":true}')

  # Stream response, accumulate full reply
  # Spinner function
  spinner() {
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    while true; do
      for (( i=0; i<${#chars}; i++ )); do
        printf "\r%s Thinking..." "${chars:$i:1}"
        sleep 0.08
      done
    done
  }

  # Start spinner in background
  spinner &
  SPINNER_PID=$!

  # Stream response, accumulate full reply
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
        printf "\r\033[K"  # Clear the spinner line
        printf "\nAssistant: "
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

  # Append assistant reply to history and log
  MESSAGES=$(echo "$MESSAGES" | jq --arg content "$FULL_RESPONSE" '. + [{"role":"assistant","content":$content}]')
  printf "%s\n" "$FULL_RESPONSE" >> "$OUTPUT_FILE"

done

printf "\nSaved to %s\n" "$OUTPUT_FILE"