"""Reference harness for iss_KonBase__konbase__71."""
import importlib.util
from pathlib import Path
_spec = importlib.util.spec_from_file_location("_mod", Path(__file__).with_name("iss_KonBase__konbase__71.py"))
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
h = _mod.make_hierarchy()
_mod.add_org(h, "root", None)
_mod.add_org(h, "a", "root")
_mod.add_org(h, "b", "root")
_mod.add_org(h, "c", "a")
_mod.add_org(h, "d", "a")
assert _mod.descendants(h, "root") == ["a", "b", "c", "d"]
assert _mod.descendants(h, "a") == ["c", "d"]
assert _mod.ancestors(h, "c") == ["a", "root"]
assert _mod.depth_of(h, "c") == 2
assert _mod.depth_of(h, "root") == 0
assert _mod.has_cycle(h) is False
# diamond/adversarial order
h2 = _mod.make_hierarchy()
_mod.add_org(h2, "root", None)
_mod.add_org(h2, "b", "root")
_mod.add_org(h2, "a", "root")
_mod.add_org(h2, "d", "a")
_mod.add_org(h2, "c", "a")
assert _mod.descendants(h2, "root") == _mod.descendants(h, "root")
# deep chain 5 levels
h3 = _mod.make_hierarchy()
prev = None
for i in range(5):
    nid = f"n{i}"
    _mod.add_org(h3, nid, prev)
    prev = nid
assert _mod.depth_of(h3, "n4") == 4
# cycle detection
h4 = _mod.make_hierarchy()
_mod.add_org(h4, "x", None)
_mod.add_org(h4, "y", "x")
h4.children["y"].append("x")
h4.parent["x"] = "y"
assert _mod.has_cycle(h4) is True
# unknown returns empty
assert _mod.descendants(h, "ghost") == []
assert _mod.ancestors(h, "ghost") == []
print("iss_KonBase__konbase__71 ref OK")
