# ---- Parse Arguments ----
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --model)  MODEL="$2";       shift 2 ;;
    --output) OUTPUT_FILE="$2"; shift 2 ;;
    --help)
      if [[ -f "$RESOURCES_DIR/help.txt" ]]; then
        cat "$RESOURCES_DIR/help.txt"
      else
        printf "${C_WARN}✗ help.txt not found.${RESET}\n"
      fi
      exit 0
      ;;
    --sysprompt)
      SYSTEM_PROMPT_PATH="$2"
      # Resolve relative path against current directory
      if [[ -f "$SYSTEM_PROMPT_PATH" ]]; then
        SYSTEM_PROMPT_PATH="$(realpath "$SYSTEM_PROMPT_PATH")"
      else
        printf "${C_WARN}✗ System prompt file not found: %s${RESET}\n" "$SYSTEM_PROMPT_PATH"
        exit 1
      fi
      shift 2
      ;;
    *)
      printf "${C_WARN}✗ Unknown parameter: %s${RESET}\n" "$1"
      exit 1
      ;;
  esac
done