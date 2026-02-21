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
    *)
      printf "${C_WARN}✗ Unknown parameter: %s${RESET}\n" "$1"
      exit 1
      ;;
  esac
done