import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_acp_194",
    Path(__file__).with_name("iss_LAA-Software-Engineering__agentic-control-plane__194.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ws = mod.load_workflows(
    ["main", "sub_a", "sub_b", "leaf"],
    [("main", "sub_a"), ("sub_a", "sub_b"), ("main", "leaf")],
)
assert mod.reachable_subworkflows(ws, "main") == ["leaf", "main", "sub_a", "sub_b"]
assert mod.validate_no_recursion(ws) == []
assert mod.max_invoke_depth(ws, "main", 3)

ws_cycle = mod.load_workflows(["a", "b"], [("a", "b"), ("b", "a")])
assert mod.validate_no_recursion(ws_cycle) == [("b", "a")]

g_diamond = mod.load_workflows(
    ["hub", "left", "right", "bot"],
    [("right", "bot"), ("hub", "left"), ("left", "bot"), ("hub", "right")],
)
assert mod.reachable_subworkflows(g_diamond, "hub") == ["bot", "hub", "left", "right"]
assert mod.reachable_subworkflows(ws, "missing") == []
print("ok")
