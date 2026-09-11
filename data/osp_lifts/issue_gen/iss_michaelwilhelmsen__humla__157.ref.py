"""Reference harness for michaelwilhelmsen/humla#157."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "humla157", HERE / "iss_michaelwilhelmsen__humla__157.py"
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader
sys.modules["humla157"] = mod
spec.loader.exec_module(mod)

load_folders = mod.load_folders
resolve_path = mod.resolve_path
list_children = mod.list_children
mkdir = mod.mkdir
subtree_paths = mod.subtree_paths
would_reparent_cycle = mod.would_reparent_cycle
reparent = mod.reparent


def main() -> None:
    g = load_folders([
        ("/", None),
        ("/personal", "/"),
        ("/personal/notes", "/personal"),
        ("/work", "/"),
        ("/work/projects", "/work"),
    ])
    assert resolve_path(g, "/personal/notes") == "/personal/notes"
    assert resolve_path(g, "personal/notes") == "/personal/notes"
    assert resolve_path(g, "/missing") is None
    assert list_children(g, "/personal") == ["/personal/notes"]
    assert subtree_paths(g, "/") == [
        "/personal",
        "/personal/notes",
        "/work",
        "/work/projects",
    ]
    newp = mkdir(g, "/work", "archive")
    assert newp == "/work/archive"
    assert list_children(g, "/work") == ["/work/archive", "/work/projects"]
    assert would_reparent_cycle(g, "/personal", "/personal/notes") is True
    try:
        reparent(g, "/personal", "/personal/notes")
        raise AssertionError("expected ValueError")
    except ValueError:
        pass
    reparent(g, "/work/projects", "/personal")
    assert resolve_path(g, "/work/projects") == "/work/projects"
    assert list_children(g, "/personal") == ["/personal/notes", "/work/projects"]
    assert list_children(g, "/nope") == []
    assert subtree_paths(g, "/nope") == []
    print("ok")


if __name__ == "__main__":
    main()
