parse_and_dispatch() {
  local response="$1"

  if [[ "$response" =~ \[CALL:([a-zA-Z_]+)\(([^)]*)\)\] ]]; then
    local func="${BASH_REMATCH[1]}"
    local raw_args="${BASH_REMATCH[2]}"
    local script="$TOOLS_DIR/${func}.py"

    if [[ ! -f "$script" ]]; then
      printf "  ${C_WARN}${BOLD}[dispatch]${RESET} ${C_WARN}No tool found: '%s'${RESET}\n" "$func"
      return 1
    fi

    # Split args on comma
    IFS=',' read -ra args <<< "$raw_args"

    python3 "$script" "${args[@]}"
  fi
}