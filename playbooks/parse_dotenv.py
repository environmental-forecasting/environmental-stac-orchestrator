#!/usr/bin/env python3
"""Print a JSON object of KEY=value pairs from a dotenv file."""

from __future__ import annotations

import json
import pathlib
import sys


def parse(path: pathlib.Path) -> dict[str, str]:
    env: dict[str, str] = {}
    if not path.is_file():
        return env
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        if stripped.startswith("export "):
            stripped = stripped[7:].lstrip()
        key, _, value = stripped.partition("=")
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        env[key.strip()] = value
    return env


if __name__ == "__main__":
    print(json.dumps(parse(pathlib.Path(sys.argv[1]))))
