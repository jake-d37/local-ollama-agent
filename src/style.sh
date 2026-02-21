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
C_DISPATCH="\033[38;5;178m"

# ---- Box drawing ----
TL="╭" TR="╮" BL="╰" BR="╯" H="─" V="│"

# ---- Header ----
draw_header() {
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
}

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