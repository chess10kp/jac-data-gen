import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_developerz-ai__universal-lsp__4",
    Path(__file__).with_name("iss_developerz-ai__universal-lsp__4.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

NODES = [
    ("app", "module", "app"),
    ("main", "file", "main.jac"),
    ("util", "file", "util.jac"),
    ("foo", "symbol", "foo"),
    ("bar", "symbol", "bar"),
    ("baz", "symbol", "baz"),
]
EDGES = [
    ("app", "main"),
    ("app", "util"),
    ("main", "foo"),
    ("main", "bar"),
    ("util", "bar"),
    ("util", "baz"),
    ("baz", "main"),
]

g = mod.load_graph(NODES, EDGES)
assert mod.bfs_typed(g, "app", "symbol") == ["bar", "baz", "foo"]
assert mod.dfs_typed(g, "app", "symbol") == ["bar", "baz", "foo"]
assert mod.bfs_typed(g, "app", "file") == ["main", "util"]
assert mod.dfs_typed(g, "app", "file") == ["main", "util"]
assert mod.bfs_typed(g, "app", "module") == ["app"]
assert mod.bfs_typed(g, "ghost", "symbol") == []

g2 = mod.load_graph(
    [
        ("hub", "module", "hub"),
        ("left", "file", "left"),
        ("right", "file", "right"),
        ("mid", "file", "mid"),
        ("target", "symbol", "target"),
    ],
    [
        ("hub", "left"),
        ("hub", "right"),
        ("left", "mid"),
        ("mid", "right"),
        ("left", "target"),
        ("right", "target"),
        ("target", "left"),
    ],
)
assert mod.bfs_typed(g2, "hub", "symbol") == ["target"]
assert mod.bfs_typed(g2, "hub", "file") == ["left", "mid", "right"]
print("ok")
