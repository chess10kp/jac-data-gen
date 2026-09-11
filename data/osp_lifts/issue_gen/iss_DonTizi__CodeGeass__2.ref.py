"""Reference harness for iss_DonTizi__CodeGeass__2."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_DonTizi__CodeGeass__2.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

g = _mod.load_tasks(["a", "b", "c"], [("a", "b"), ("b", "c")], done=["a"])
assert _mod.has_cycle(g) is False
assert _mod.ready_tasks(g) == ["b"]
cyc = _mod.load_tasks(["x", "y"], [("x", "y"), ("y", "x")])
assert _mod.has_cycle(cyc) is True

print("iss_DonTizi__CodeGeass__2 ref OK")
