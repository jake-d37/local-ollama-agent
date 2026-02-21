#!/usr/bin/env python3
import os
import sys


def mkdir(name: str):
    """Creates a directory with the given name in the current working directory.
    Example: [CALL:mkdir(my_folder)]
    """
    os.makedirs(name, exist_ok=True)
    print(f"Created directory: {os.path.join(os.getcwd(), name)}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <name>", file=sys.stderr)
        sys.exit(1)
    mkdir(sys.argv[1])