import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_Gentleman-Programming__gentle-ai__2295",
    Path(__file__).with_name("iss_Gentleman-Programming__gentle-ai__2295.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

load_workflow = mod.load_workflow
reachable_states = mod.reachable_states
blocks_archive = mod.blocks_archive

W = load_workflow(
    [("verify", "auth-v1"), ("review", "auth-v2"), ("archive", "auth-v2")],
    [("verify", "review"), ("review", "archive")],
)
assert reachable_states(W, "verify") == ["archive", "review", "verify"]
assert blocks_archive(W, "verify", "auth-v2") is True
assert blocks_archive(W, "archive", "auth-v2") is False

CYCLE = load_workflow(
    [("verify", "a"), ("review", "b"), ("verify_refresh", "c")],
    [("verify", "review"), ("review", "verify_refresh"), ("verify_refresh", "verify")],
)
assert reachable_states(CYCLE, "verify") == ["review", "verify", "verify_refresh"]

DIAMOND = load_workflow(
    [("start", "x"), ("left", "x"), ("right", "x"), ("end", "x")],
    [("start", "left"), ("start", "right"), ("left", "end"), ("right", "end")],
)
assert reachable_states(DIAMOND, "start") == ["end", "left", "right", "start"]

assert reachable_states(W, "missing") == []

print("ok")
