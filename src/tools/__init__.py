"""
Tool registry and dispatch.

To add a new tool:
1. Create a file in this directory (e.g. search.py)
2. Define a function matching the signature: def run(args: dict) -> str
3. Register it below in TOOL_REGISTRY

Session will call dispatch(tool_name, args) when a pattern is matched
in the assistant's response.
"""

from typing import Callable

# TOOL_REGISTRY maps tool names to handler functions.
# Example:
#   from .search import run as search_run
#   TOOL_REGISTRY = {"search": search_run}
TOOL_REGISTRY: dict[str, Callable[[dict], str]] = {}


def dispatch(tool_name: str, args: dict) -> str:
    """Dispatch a tool call by name. Returns the tool's string output."""
    handler = TOOL_REGISTRY.get(tool_name)
    if handler is None:
        return f"[Tool '{tool_name}' not found]"
    return handler(args)