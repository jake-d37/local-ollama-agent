"""Ollama API client — handles streaming chat completions."""

import json
from typing import Iterator
import requests

OLLAMA_URL = "http://localhost:11434/api/chat"


class OllamaError(Exception):
    pass


def stream_chat(model: str, messages: list[dict]) -> Iterator[tuple[str, dict | None]]:
    """
    Stream a chat completion from Ollama.

    Yields:
        (content_chunk, done_metadata) tuples.
        content_chunk is a string (may be empty).
        done_metadata is the final JSON payload when stream ends, else None.

    Raises:
        OllamaError on connection or API errors.
    """
    payload = {
        "model": model,
        "messages": messages,
        "stream": True,
    }

    try:
        response = requests.post(
            OLLAMA_URL,
            json=payload,
            stream=True,
            timeout=120,
        )
        response.raise_for_status()
    except requests.exceptions.ConnectionError:
        raise OllamaError(
            "Could not connect to Ollama at localhost:11434. Is it running?"
        )
    except requests.exceptions.HTTPError as e:
        raise OllamaError(f"Ollama API error: {e}")

    for raw_line in response.iter_lines():
        if not raw_line:
            continue
        try:
            data = json.loads(raw_line)
        except json.JSONDecodeError:
            continue

        content = data.get("message", {}).get("content", "")
        done = data.get("done", False)

        if done:
            yield content, data
            return
        else:
            yield content, None