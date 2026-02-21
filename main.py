#!/usr/bin/env python3
"""Ollama Chat Terminal — entry point."""

from ollama_chat.cli import parse_args
from ollama_chat.session import ChatSession

def main():
    args = parse_args()
    session = ChatSession(model=args.model, output_file=args.output)
    session.run()


if __name__ == "__main__":
    main()