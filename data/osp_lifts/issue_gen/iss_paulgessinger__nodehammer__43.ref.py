"""Reference harness: exercises every public function of iss_paulgessinger__nodehammer__43."""
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "nh43", Path(__file__).parent / "iss_paulgessinger__nodehammer__43.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["nh43"] = mod
spec.loader.exec_module(mod)

SceneGraph, CycleError = mod.SceneGraph, mod.CycleError

s = SceneGraph()
s.add_node("root", local=2.0)
s.add_node("arm", parent="root", local=0.5)
s.add_node("wrist", parent="arm", local=4.0)
s.add_node("other", parent="root", local=1.0)

assert s.children("root") == ["arm", "other"]
assert s.ancestors("wrist") == ["arm", "root"]
assert s.world_transform("wrist") == 4.0
assert s.world_transform("root") == 2.0
worlds = s.compute_world_transforms()
assert worlds == {"root": 2.0, "arm": 1.0, "wrist": 4.0, "other": 2.0}, worlds
assert s.reachable("root") == ["arm", "other", "root", "wrist"]
assert s.reachable("arm") == ["arm", "wrist"]
assert s.validate_acyclic()

# Diamond: shared leaf reachable via two branches, listed once.
k = SceneGraph()
k.add_node("a")
k.add_node("b1", parent="a")
k.add_node("b2", parent="a")
k.add_node("shared", parent="b1")
k.add_node("sh2", parent="b2")
assert k.reachable("a") == ["a", "b1", "b2", "sh2", "shared"]

# Cycle: parent loop raises on every walk entry point.
c = SceneGraph()
c.add_node("x")
c.add_node("y", parent="x")
c.add_node("z", parent="y")
c.parent["x"] = "z"  # close the loop x -> y -> z -> x
for probe in (lambda: c.world_transform("x"), lambda: c.validate_acyclic()):
    try:
        probe()
        raise AssertionError("expected CycleError")
    except CycleError:
        pass
# Reachability terminates with a finite claim-set instead of hanging.
assert c.reachable("x") == ["x", "y", "z"], c.reachable("x")

# Errors.
try:
    s.add_node("bad", parent="ghost")
    raise AssertionError("expected KeyError")
except KeyError:
    pass

print("nodehammer 43 ref OK")
