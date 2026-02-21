"""
Response pattern matching for tool invocation.

When the assistant response contains a recognized pattern, this module
extracts the tool name and arguments and triggers dispatch.

Example pattern (XML-style):
    <tool name="search"><arg name="query">latest AI news</arg></tool>

Usage in session.py:
    from .patterns import extract_tool_calls
    from .tools import dispatch

    calls = extract_tool_calls(full_response)
    for tool_name, args in calls:
        result = dispatch(tool_name, args)
        # inject result back into conversation as a system/tool message
"""

import re
from typing import Iterator

# Matches: <tool name="tool_name">...</tool>
_TOOL_PATTERN = re.compile(
    r'<tool\s+name="(?P<name>[^"]+)"[^>]*>(?P<body>.*?)</tool>',
    re.DOTALL,
)

# Matches: <arg name="key">value</arg>
_ARG_PATTERN = re.compile(
    r'<arg\s+name="(?P<key>[^"]+)">(?P<value>.*?)</arg>',
    re.DOTALL,
)


def extract_tool_calls(text: str) -> Iterator[tuple[str, dict]]:
    """
    Scan assistant response text for tool call patterns.

    Yields:
        (tool_name, args_dict) for each match found.
    """
    for match in _TOOL_PATTERN.finditer(text):
        tool_name = match.group("name")
        body = match.group("body")
        args = {m.group("key"): m.group("value").strip() for m in _ARG_PATTERN.finditer(body)}
        yield tool_name, args