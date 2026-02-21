"""Core chat session — orchestrates the conversation loop."""

import signal
import sys
from pathlib import Path

from rich.live import Live
from rich.spinner import Spinner
from rich.text import Text
from rich.console import Console

from .api import stream_chat, OllamaError
from .logger import Logger
from .tui import (
    console,
    print_banner,
    print_help,
    print_model,
    print_history_cleared,
    print_summary,
    print_token_count,
    get_user_input,
)

SLASH_COMMANDS = {"/exit", "/clear", "/model", "/help", "exit"}


class ChatSession:
    def __init__(self, model: str, output_file: Path) -> None:
        self.model = model
        self.output_file = output_file
        self.messages: list[dict] = []
        self.msg_count = 0
        self.logger = Logger(output_file, model)
        self._register_signals()

    # ── Signal handling ──────────────────────────────────────

    def _register_signals(self) -> None:
        signal.signal(signal.SIGINT, self._handle_interrupt)
        signal.signal(signal.SIGTERM, self._handle_interrupt)

    def _handle_interrupt(self, *_) -> None:
        console.print("\n\n[yellow]Interrupted.[/yellow] Saving session...")
        self.logger.log_event("Session interrupted")
        print_summary(self.msg_count, self.output_file)
        sys.exit(0)

    # ── Slash commands ───────────────────────────────────────

    def _handle_command(self, cmd: str) -> bool:
        """Handle a slash command. Returns True if a command was handled."""
        match cmd.strip():
            case "/exit" | "exit":
                return False  # signal to break main loop
            case "/clear":
                self.messages = []
                print_history_cleared()
                return True
            case "/model":
                print_model(self.model)
                return True
            case "/help":
                print_help()
                return True
            case _:
                console.print(f"  [red]Unknown command:[/red] {cmd}\n")
                return True

    # ── Streaming response ───────────────────────────────────

    def _stream_response(self) -> tuple[str, int]:
        """
        Stream the assistant response to stdout with a spinner,
        then return (full_response_text, token_count).
        """
        full_response = ""
        token_count = 0
        first_token = True

        # Show spinner until first token arrives
        spinner = Spinner("dots", text=" Thinking...", style="dim")

        with Live(spinner, console=console, transient=True, refresh_per_second=12):
            for chunk, done_meta in stream_chat(self.model, self.messages):
                if first_token and chunk:
                    first_token = False
                    # Live context will clean itself up on exit

                full_response += chunk

                if done_meta is not None:
                    token_count = done_meta.get("eval_count", 0)

        # Print full response after spinner clears
        console.print(
            Text.assemble(
                (" " + " Assistant › ", "green bold"),
                (full_response, ""),
            )
        )

        return full_response, token_count

    # ── Main loop ────────────────────────────────────────────

    def run(self) -> None:
        print_banner(self.model, self.output_file)

        while True:
            try:
                user_input = get_user_input()
            except (EOFError, KeyboardInterrupt):
                break

            if not user_input.strip():
                continue

            # Handle commands
            if user_input.startswith("/") or user_input == "exit":
                should_continue = self._handle_command(user_input)
                if not should_continue:
                    break
                continue

            # Add to history and call API
            self.messages.append({"role": "user", "content": user_input})

            try:
                full_response, token_count = self._stream_response()
            except OllamaError as e:
                console.print(f"\n  [red]Error:[/red] {e}\n")
                self.messages.pop()  # Remove the failed user message
                continue

            # Update history and log
            self.messages.append({"role": "assistant", "content": full_response})
            self.logger.log_exchange(user_input, full_response)
            self.msg_count += 1

            if token_count:
                print_token_count(token_count)

            console.print()

        self.logger.log_event(f"Session ended — {self.msg_count} exchanges")
        print_summary(self.msg_count, self.output_file)