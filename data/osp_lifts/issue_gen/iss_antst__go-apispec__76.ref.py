import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_antst__go-apispec__76",
    Path(__file__).with_name("iss_antst__go-apispec__76.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

load_callgraph = mod.load_callgraph
reachable_handlers = mod.reachable_handlers
exported_paths = mod.exported_paths

CHAIN = load_callgraph(
    handlers=["main", "setup", "register"],
    calls=[("main", "setup"), ("setup", "register")],
    routes=[("register", "/users")],
    entries=["main"],
)
assert reachable_handlers(CHAIN, "main") == ["main", "register", "setup"]
assert exported_paths(CHAIN) == ["/users"]

CYCLE = load_callgraph(
    handlers=["main", "a", "b", "c", "register"],
    calls=[
        ("main", "a"),
        ("a", "b"),
        ("b", "c"),
        ("c", "a"),
        ("c", "register"),
    ],
    routes=[("register", "/ping")],
    entries=["main"],
)
assert reachable_handlers(CYCLE, "main") == ["a", "b", "c", "main", "register"]
assert exported_paths(CYCLE) == ["/ping"]

DIAMOND = load_callgraph(
    handlers=["main", "left", "right", "register"],
    calls=[
        ("main", "left"),
        ("main", "right"),
        ("left", "register"),
        ("right", "register"),
    ],
    routes=[("register", "/api")],
    entries=["main"],
)
assert reachable_handlers(DIAMOND, "main") == ["left", "main", "register", "right"]
assert exported_paths(DIAMOND) == ["/api"]

MULTI = load_callgraph(
    handlers=["e1", "e2", "h1", "h2"],
    calls=[("e1", "h1"), ("e2", "h2")],
    routes=[("h1", "/one"), ("h2", "/two")],
    entries=["e1", "e2"],
)
assert exported_paths(MULTI) == ["/one", "/two"]

EMPTY = load_callgraph(
    handlers=["main", "orphan"],
    calls=[],
    routes=[("orphan", "/hidden")],
    entries=["main"],
)
assert exported_paths(EMPTY) == []

assert reachable_handlers(CHAIN, "missing") == []
assert exported_paths(
    load_callgraph(["solo"], [], [("solo", "/solo")], ["solo"])
) == ["/solo"]

print("ok")
