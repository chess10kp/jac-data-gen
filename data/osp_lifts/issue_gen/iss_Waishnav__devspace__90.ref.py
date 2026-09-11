"""Reference harness for Waishnav/devspace#90."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "ds90", HERE / "iss_Waishnav__devspace__90.py"
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader
sys.modules["ds90"] = mod
spec.loader.exec_module(mod)

load_tree = mod.load_tree
discover_agent_files = mod.discover_agent_files


def _main_specs() -> list[tuple[str, str | None, bool]]:
    return [
        ("/ws", None, False),
        ("/ws/p1", "/ws", True),
        ("/ws/p1/src", "/ws/p1", True),
        ("/ws/p1/src/deep", "/ws/p1/src", False),
        ("/ws/p2", "/ws", True),
    ]


def main() -> None:
    g = load_tree(_main_specs())
    assert discover_agent_files(g, "/ws") == [
        "/ws/p1",
        "/ws/p1/src",
        "/ws/p2",
    ]
    assert discover_agent_files(g, "/ws/p1") == [
        "/ws/p1",
        "/ws/p1/src",
    ]
    assert discover_agent_files(g, "/ws/p1/src/deep") == []
    assert discover_agent_files(g, "/missing") == []

    cyc = load_tree([
        ("/a", None, False),
        ("/b", "/a", False),
        ("/c", "/b", True),
        ("/a", "/c", False),
    ])
    assert discover_agent_files(cyc, "/a") == ["/c"]

    wide = load_tree([
        ("/r", None, False),
        ("/r/p1", "/r", True),
        ("/r/p2", "/r", True),
        ("/r/p3", "/r", True),
        ("/r/p1/nested", "/r/p1", True),
    ])
    assert discover_agent_files(wide, "/r") == [
        "/r/p1",
        "/r/p1/nested",
        "/r/p2",
        "/r/p3",
    ]
    print("ok")


if __name__ == "__main__":
    main()
