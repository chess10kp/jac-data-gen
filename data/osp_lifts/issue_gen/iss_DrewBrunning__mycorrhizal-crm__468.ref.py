"""Reference harness for iss_DrewBrunning__mycorrhizal-crm__468."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_DrewBrunning__mycorrhizal-crm__468.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

g = _mod.load_crm(
    ["alice", "bob", "carol", "dave", "eve"],
    [("alice", "bob"), ("bob", "carol"), ("alice", "dave"), ("dave", "eve")],
)
assert _mod.reachable_contacts(g, "alice") == ["bob", "carol", "dave", "eve"]
assert _mod.relationship_hops(g, "alice") == 2
assert _mod.hub_neighbors(g, "alice") == ["bob", "dave"]
assert _mod.reachable_contacts(g, "ghost") == []

diamond = _mod.load_crm(
    ["hub", "a", "b", "tip"],
    [("hub", "a"), ("hub", "b"), ("a", "tip"), ("b", "tip")],
)
assert _mod.reachable_contacts(diamond, "hub") == ["a", "b", "tip"]

print("iss_DrewBrunning__mycorrhizal-crm__468 ref OK")
