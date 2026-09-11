import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_myco_469",
    Path(__file__).with_name("iss_DrewBrunning__mycorrhizal-crm__469.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

G = mod.load_contacts(
    [("alice", "person"), ("bob", "person"), ("carol", "person"), ("hub", "org")],
    [("alice", "hub"), ("bob", "hub"), ("carol", "hub"), ("hub", "bob")],
)
assert mod.reachable_contacts(G, "alice", 2) == ["bob", "carol", "hub"]
assert mod.hops_between(G, "alice", "carol") == 2
assert mod.hub_contacts(G, 3) == ["hub"]

assert mod.reachable_contacts(G, "missing", 2) == []
assert mod.hops_between(G, "alice", "missing") is None
print("ok")
