"""Handles writing conversation logs to disk."""

from datetime import datetime
from pathlib import Path


class Logger:
    def __init__(self, output_file: Path, model: str) -> None:
        self.path = output_file
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.path, "w") as f:
            f.write(f"Model: {model}\nStarted: {datetime.now()}\n\n")

    def log_exchange(self, user: str, assistant: str) -> None:
        with open(self.path, "a") as f:
            f.write(f"You: {user}\n\nAssistant:\n{assistant}\n\n")

    def log_event(self, message: str) -> None:
        with open(self.path, "a") as f:
            f.write(f"[{datetime.now()}] {message}\n")