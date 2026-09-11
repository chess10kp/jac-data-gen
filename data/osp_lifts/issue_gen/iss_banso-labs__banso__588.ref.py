import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_banso-labs__banso__588",
    Path(__file__).with_name("iss_banso-labs__banso__588.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

DAG = mod.load_call_graph(
    ["main", "setup", "register", "handler"],
    [("main", "setup"), ("setup", "register"), ("register", "handler")],
)
assert mod.forward_reachable(DAG, "main", 3) == ["handler", "main", "register", "setup"]
assert mod.forward_reachable(DAG, "main", 1) == ["main", "setup"]
assert mod.is_reachable(DAG, "main", "handler") is True
assert mod.is_reachable(DAG, "handler", "main") is False
assert mod.caller_chain(DAG, "handler") == ["handler", "register", "setup", "main"]

CYCLE = mod.load_call_graph(
    ["a", "b", "c", "d"],
    [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d")],
)
assert mod.forward_reachable(CYCLE, "a", 5) == ["a", "b", "c", "d"]
assert mod.caller_chain(CYCLE, "d") == ["d", "c", "b", "a"]

DIAMOND = mod.load_call_graph(
    ["seed", "left", "right", "sink"],
    [("seed", "left"), ("seed", "right"), ("left", "sink"), ("right", "sink")],
)
assert mod.forward_reachable(DIAMOND, "seed", 4) == ["left", "right", "seed", "sink"]

assert mod.forward_reachable(DAG, "missing", 2) == []
assert mod.is_reachable(DAG, "missing", "main") is False
print("ok")
