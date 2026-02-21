"""CLI argument parsing."""

import argparse
from datetime import datetime
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Ollama Chat Terminal",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--model",
        default="qwen2.5:14b",
        help="Ollama model to use (default: qwen2.5:14b)",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Path to log file (default: outputs/ollama_output_<timestamp>.txt)",
    )

    args = parser.parse_args()

    if args.output is None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        args.output = Path("outputs") / f"ollama_output_{timestamp}.txt"
    else:
        args.output = Path(args.output)

    return args