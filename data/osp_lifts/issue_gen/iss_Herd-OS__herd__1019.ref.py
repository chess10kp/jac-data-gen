"""Reference harness for iss_Herd-OS__herd__1019."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Herd-OS__herd__1019.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

g = _mod.load_dispatch(
    ["lint", "test", "build", "deploy"],
    [("lint", "test"), ("test", "build"), ("build", "deploy")],
    {"lint": "done"},
)
assert _mod.frontier_jobs(g) == ["test"]
assert _mod.blocked_by(g, "deploy") == ["build"]
assert _mod.dispatch_ready_count(g) == 1

g2 = _mod.load_dispatch(
    ["a", "b", "c", "d"],
    [("a", "c"), ("b", "c"), ("c", "d")],
)
assert _mod.frontier_jobs(g2) == ["a", "b"]

print("iss_Herd-OS__herd__1019 ref OK")
