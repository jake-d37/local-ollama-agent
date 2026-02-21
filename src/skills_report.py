#!/usr/bin/env python3
"""
skills_report.py
Parses all public functions from Python files in a given directory and prints
a formatted skills report showing each tool's signature and docstring.

Usage:
    python3 skills_report.py <tools_dir>
"""

import ast
import os
import sys


TOOL_CALLING_RULES = """
TOOL CALLING RULES — follow these strictly:
- NEVER call a tool unless the user has explicitly asked you to perform that operation.
- NEVER call tools in a greeting, example, or to demonstrate capability.
- NEVER call tools speculatively or as a suggestion of what could be done.
- If you are unsure whether the user wants an action performed, ask first.
- A user saying "hello" or asking a question is never a reason to call a tool.
- NEVER call a tool to explain or demonstrate what it does. If a user asks what tools are available or what a tool does, describe it in plain text only.
""".strip()


def parse_tools(tools_dir: str) -> list[tuple[str, str, str]]:
    """Return a list of (name, signature, docstring) for every public function
    found across all .py files in tools_dir."""
    entries = []

    for fname in sorted(os.listdir(tools_dir)):
        if not fname.endswith(".py") or fname.endswith(".example.py"):
            continue

        fpath = os.path.join(tools_dir, fname)
        with open(fpath, "r", encoding="utf-8") as f:
            source = f.read()

        try:
            tree = ast.parse(source, filename=fpath)
        except SyntaxError as e:
            print(f"[skipped {fname}: SyntaxError: {e}]", file=sys.stderr)
            continue

        for node in ast.walk(tree):
            if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                continue
            if node.name.startswith("_"):
                continue

            sig = build_signature(node.args)
            docstring = ast.get_docstring(node) or ""
            entries.append((node.name, sig, docstring))

    return entries


def build_signature(args: ast.arguments) -> str:
    """Reconstruct a human-readable argument signature from an AST arguments node."""
    all_args = []

    num_args = len(args.args)
    num_defaults = len(args.defaults)

    for i, arg in enumerate(args.args):
        annotation = f":{ast.unparse(arg.annotation)}" if arg.annotation else ""
        default_offset = i - (num_args - num_defaults)
        default_val = f"={ast.unparse(args.defaults[default_offset])}" if default_offset >= 0 else ""
        all_args.append(f"{arg.arg}{annotation}{default_val}")

    if args.vararg:
        ann = f":{ast.unparse(args.vararg.annotation)}" if args.vararg.annotation else ""
        all_args.append(f"*{args.vararg.arg}{ann}")

    for i, arg in enumerate(args.kwonlyargs):
        annotation = f":{ast.unparse(arg.annotation)}" if arg.annotation else ""
        default_val = f"={ast.unparse(args.kw_defaults[i])}" if args.kw_defaults[i] is not None else ""
        all_args.append(f"{arg.arg}{annotation}{default_val}")

    if args.kwarg:
        ann = f":{ast.unparse(args.kwarg.annotation)}" if args.kwarg.annotation else ""
        all_args.append(f"**{args.kwarg.arg}{ann}")

    return ", ".join(all_args)


def render_report(entries: list[tuple[str, str, str]]) -> None:
    """Print the formatted skills report to stdout."""
    print("You have access to the following tools. To call a tool, emit a line in")
    print("this exact format anywhere in your response:")
    print()
    print("  [CALL:function_name(arg1,arg2)]")
    print()
    print("Available tools:")
    print()

    for name, sig, doc in entries:
        print(f"  {name}({sig})")
        if doc:
            for line in doc.splitlines():
                stripped = line.strip()
                print(f"    {stripped}" if stripped else "")
        print()

    print(TOOL_CALLING_RULES)


def main() -> None:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <tools_dir>", file=sys.stderr)
        sys.exit(1)

    tools_dir = sys.argv[1]
    if not os.path.isdir(tools_dir):
        print(f"Error: '{tools_dir}' is not a directory.", file=sys.stderr)
        sys.exit(1)

    entries = parse_tools(tools_dir)
    render_report(entries)


if __name__ == "__main__":
    main()