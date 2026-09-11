"""Reference harness for iss_VOID-TECHNOLOGY-INC__PyBun__404."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_VOID-TECHNOLOGY-INC__PyBun__404.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
from iss_VOID-TECHNOLOGY-INC__PyBun__404 import scan_directory

assert (
    scan_directory(
        "pkg",
        [("pkg", "loop"), ("loop", "pkg")],
        ["pkg"],
    )
    == ["pkg"]
)

assert (
    scan_directory(
        "a",
        [("a", "b"), ("b", "back"), ("back", "a")],
        ["a", "b"],
    )
    == ["a", "b"]
)

assert (
    scan_directory(
        "root",
        [
            ("root", "left"),
            ("root", "right"),
            ("left", "shared"),
            ("right", "shared"),
            ("shared", "leaf"),
        ],
        ["left", "shared", "leaf"],
    )
    == ["leaf", "left", "shared"]
)

assert scan_directory("missing", [("a", "b")], ["a"]) == []

assert (
    scan_directory(
        "root",
        [("root", "pkg")],
        ["pkg", "missing"],
    )
    == ["pkg"]
)
print("iss_VOID-TECHNOLOGY-INC__PyBun__404 ref OK")
