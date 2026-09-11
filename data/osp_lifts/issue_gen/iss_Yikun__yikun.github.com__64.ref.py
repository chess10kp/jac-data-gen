"""Reference harness for iss_Yikun__yikun.github.com__64."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Yikun__yikun.github.com__64.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
tree = _mod.NestedResourceTree()
tree.add_provider("host")
tree.add_provider("numa0", "host")
tree.add_provider("numa1", "host")
tree.set_inventory("host", "MEMORY_MB", 192 * 1024)
tree.set_inventory("numa0", "MEMORY_MB", 128 * 1024)
tree.set_inventory("numa1", "MEMORY_MB", 64 * 1024)
tree.allocate("numa0", "MEMORY_MB", 112 * 1024)
tree.allocate("numa1", "MEMORY_MB", 48 * 1024)
assert tree.descendants("host") == ["host", "numa0", "numa1"]
assert tree.aggregated_free("host", "MEMORY_MB") == (192 + 16 + 16) * 1024
assert tree.can_place("host", "MEMORY_MB", 32 * 1024, numa_aware=False) is True
assert tree.can_place("host", "MEMORY_MB", 32 * 1024, numa_aware=True) is False
assert tree.can_place("host", "MEMORY_MB", 16 * 1024, numa_aware=True) is True
assert tree.ancestor_chain("numa1") == ["host", "numa1"]
assert tree.ancestor_chain("host") == ["host"]

try:
    tree.allocate("numa0", "MEMORY_MB", 32 * 1024)
    assert False, "expected local capacity rejection"
except _mod.PlacementError:
    pass

try:
    tree.add_provider("orphan", "missing")
    assert False, "expected unknown parent rejection"
except _mod.PlacementError:
    pass

try:
    tree.add_provider("host")
    assert False, "expected duplicate provider rejection"
except _mod.PlacementError:
    pass

try:
    tree.set_inventory("ghost", "MEMORY_MB", 1)
    assert False, "expected unknown provider rejection"
except _mod.PlacementError:
    pass

try:
    tree.descendants("ghost")
    assert False, "expected unknown root rejection"
except _mod.PlacementError:
    pass

try:
    tree.ancestor_chain("ghost")
    assert False, "expected unknown provider rejection"
except _mod.PlacementError:
    pass

tree2 = _mod.NestedResourceTree()
tree2.add_provider("r")
tree2.add_provider("c1", "r")
tree2.add_provider("c2", "r")
assert tree2.descendants("r") == ["r", "c1", "c2"]
print("iss_Yikun__yikun.github.com__64 ref OK")
