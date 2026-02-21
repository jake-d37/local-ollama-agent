#!/usr/bin/env bash
# Reads docstrings from Python files in $TOOLS_DIR and prints a skills report.

set -euo pipefail

RESOURCES_DIR="$(dirname "$0")/resources"
SCRIPTS_DIR="$(dirname "$0")/src"

source "$RESOURCES_DIR/config.conf"

if [[ ! -d "$TOOLS_DIR" ]]; then
  echo "Error: TOOLS_DIR='$TOOLS_DIR' is not a directory." >&2
  exit 1
fi

python3 "$PROJECT_ROOT/src/skills_report.py" "$TOOLS_DIR" > "$PROJECT_ROOT/skills_report.txt"
echo "Report written to $PROJECT_ROOT/skills_report.txt"