dump_prompt() {
  PROMPT_DUMP_FILE="outputs/prompt_dump_$TIMESTAMP.txt"
  echo "$MESSAGES" | jq '.' > "$PROMPT_DUMP_FILE"
  printf "\n  ${C_LABEL}Prompt dumped to ${RESET}${C_ACCENT}%s${RESET}\n\n" "$PROMPT_DUMP_FILE"
}