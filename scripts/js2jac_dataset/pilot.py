#!/usr/bin/env python3
"""ENTRYPOINT — Pilot A corpus (100 deterministic React->Jac components).

The pilot is the byte-stable benchmark corpus: fixtures generated to a seed,
converted, and validated through `jac check`. Nothing here calls the network.

Usage:
  ./pilot.py generate            # regenerate sources + convert (deterministic)
  ./pilot.py validate            # jac-check every record, refresh manifest
  ./pilot.py generate --out DIR  # see pilot/generate_pilot.py -h for flags
"""
import runpy
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent

USAGE = __doc__

def main() -> int:
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd not in ("generate", "validate"):
        print(USAGE)
        return 2 if cmd else 0
    sys.argv[0] = "pilot.py"
    script = HERE / ("pilot/generate_pilot.py" if cmd == "generate"
                     else "pilot/validate.py")
    runpy.run_path(str(script), run_name="__main__")
    return 0


if __name__ == "__main__":
    sys.exit(main())
