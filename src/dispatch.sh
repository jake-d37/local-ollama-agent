parse_and_dispatch() {
  local response="$1"
  local call_pattern='\[CALL:([a-zA-Z_]+)\(([^)]*)\)\]'
  local remaining="$response"

  while [[ "$remaining" =~ $call_pattern ]]; do
    local func="${BASH_REMATCH[1]}"
    local raw_args="${BASH_REMATCH[2]}"
    local script="$TOOLS_DIR/${func}.py"

    if [[ ! -f "$script" ]]; then
      printf "  ${C_WARN}${BOLD}[dispatch]${RESET} ${C_WARN}No tool found: '%s'${RESET}\n" "$func"
    else
      printf "  ${C_DISPATCH}${BOLD}[dispatch]${RESET} ${C_DISPATCH}Calling tool: %s(%s)\n" "$func" "$raw_args"

      # Split args on comma
      IFS=',' read -ra args <<< "$raw_args"
      python3 "$script" "${args[@]}"
    fi

    # Chop off everything up to and including this match so the loop advances
    remaining="${remaining#*"${BASH_REMATCH[0]}"}"
  done
}