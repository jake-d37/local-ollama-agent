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

# ---- Validate model ----
if [[ -z "$MODEL" ]]; then
  echo "Error: --model is required"
  echo "Usage: ./run_local_agent --model model_name [--output file.txt]"
  exit 1
fi

echo "Enter your prompt:"
read -r USER_PROMPT

echo -e "\nRunning model: $MODEL...\n"
echo "Prompt: $USER_PROMPT" > "$OUTPUT_FILE"
echo "------------------------" >> "$OUTPUT_FILE"

# Stream output to both terminal and file
ollama run "$MODEL" "$USER_PROMPT" | tee -a "$OUTPUT_FILE"

echo -e "\n\nSaved to $OUTPUT_FILE"