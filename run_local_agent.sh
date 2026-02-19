#!/bin/bash

# should take an input or use this as default
MODEL="qwen2.5:14b"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="outputs/ollama_output_$TIMESTAMP.txt"

echo "Enter your prompt:"
read -r USER_PROMPT

echo "Running model: $MODEL..."
echo "Prompt: $USER_PROMPT" > "$OUTPUT_FILE"
echo "------------------------" >> "$OUTPUT_FILE"

# Stream output to both terminal and file
ollama run "$MODEL" "$USER_PROMPT" | tee -a "$OUTPUT_FILE"

echo -e "\n\nSaved to $OUTPUT_FILE"