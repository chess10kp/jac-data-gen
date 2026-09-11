"""Reference harness: exercises every public function of iss_yogaprastyoo__hierarchical-task-api__79."""
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "ws79", Path(__file__).parent / "iss_yogaprastyoo__hierarchical-task-api__79.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["ws79"] = mod
spec.loader.exec_module(mod)

t = mod.WorkspaceTree()
t.add("root", "Root")
t.add("eng", "Engineering", "root")
t.add("plat", "Platform", "eng")
t.add("app", "Apps", "eng")
t.add("ops", "Ops", "root")

assert t.depth_of("plat") == 2
assert t.depth_of("root") == 0
assert t.collect_descendant_ids("root") == ["app", "eng", "ops", "plat"]
assert t.collect_descendant_ids("eng") == ["app", "plat"]
assert t.collect_descendant_ids("plat") == []
assert t.is_descendant("plat", "root")
assert t.is_descendant("plat", "eng")
assert not t.is_descendant("plat", "app")

# Depth cap: a fourth level under plat is rejected.
try:
    t.add("deep", "Deep", "plat")
    raise AssertionError("expected max_depth ValueError")
except ValueError:
    pass

# Move: legal re-parent.
t.move("plat", "app")
assert t.is_descendant("plat", "app") and not t.is_descendant("plat", "ops")

# Move under own descendant refused.
try:
    t.move("app", "plat")
    raise AssertionError("expected cycle ValueError")
except ValueError:
    pass

# Self move refused.
try:
    t.move("app", "app")
    raise AssertionError("expected cycle ValueError")
except ValueError:
    pass

# Archive removes subtree and ids disappear from the registry.
removed = t.archive("app")
assert removed == ["app", "plat"], removed
assert "app" not in t.parent
assert sorted(t.collect_descendant_ids("root")) == ["eng", "ops"]

# Errors.
try:
    t.move("ghost", "root")
    raise AssertionError("expected KeyError")
except KeyError:
    pass
# Dangling mid-chain reference fails closed with KeyError.
t2 = mod.WorkspaceTree()
t2.add("r", "R")
t2.add("mid", "M", "r")
t2.add("leaf", "L", "mid")
del t2.parent["mid"]  # simulate corrupted registry
try:
    t2.is_descendant("leaf", "r")
    raise AssertionError("expected KeyError for dangling ancestor ref")
except KeyError:
    pass

print("hierarchical-task-api 79 ref OK")
