"""Reference harness for July-NANA/OpenAnban#123."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "oa123", HERE / "iss_July-NANA__OpenAnban__123.py"
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader
sys.modules["oa123"] = mod
spec.loader.exec_module(mod)

load_tree = mod.load_tree
discover_skills = mod.discover_skills


def _main_specs() -> list[tuple[str, str | None, bool]]:
    return [
        ("/skills", None, False),
        ("/skills/coding", "/skills", True),
        ("/skills/coding/python", "/skills/coding", True),
        ("/skills/coding/python/advanced", "/skills/coding/python", False),
        ("/skills/coding/tools", "/skills/coding", True),
        ("/skills/docs", "/skills", True),
    ]


def main() -> None:
    g = load_tree(_main_specs())
    assert discover_skills(g, "/skills") == [
        "/skills/coding",
        "/skills/coding/python",
        "/skills/coding/tools",
        "/skills/docs",
    ]
    assert discover_skills(g, "/skills/coding") == [
        "/skills/coding",
        "/skills/coding/python",
        "/skills/coding/tools",
    ]
    assert discover_skills(g, "/skills/coding/python/advanced") == []
    assert discover_skills(g, "/missing") == []

    # cycle via late reparent in specs (symlink-like loop)
    cyc = load_tree([
        ("/a", None, False),
        ("/b", "/a", False),
        ("/c", "/b", True),
        ("/a", "/c", False),
    ])
    assert discover_skills(cyc, "/a") == ["/c"]

    # adversarial breadth: many sibling skill leaves + deep branch
    wide = load_tree([
        ("/r", None, False),
        ("/r/w1", "/r", True),
        ("/r/w2", "/r", True),
        ("/r/w3", "/r", True),
        ("/r/w1/deep", "/r/w1", True),
    ])
    assert discover_skills(wide, "/r") == [
        "/r/w1",
        "/r/w1/deep",
        "/r/w2",
        "/r/w3",
    ]
    print("ok")


if __name__ == "__main__":
    main()
