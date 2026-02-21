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

print_warning() {
  local message="$1"
  printf "${C_WARN}  ⚠  %s${RESET}\n\n" "$message"
}