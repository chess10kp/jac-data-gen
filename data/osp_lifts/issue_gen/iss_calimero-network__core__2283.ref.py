import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_calimero-network__core__2283",
    Path(__file__).with_name("iss_calimero-network__core__2283.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ns = mod.load_namespace(
    ["root", "team-a", "team-b", "proj-x"],
    [("root", "team-a"), ("root", "team-b"), ("team-a", "proj-x")],
    [
        ("root", "alice"),
        ("team-a", "alice"),
        ("proj-x", "alice"),
        ("team-b", "bob"),
    ],
)
assert mod.scopes_for_member(ns, "alice", "root") == ["proj-x", "root", "team-a"]
assert mod.leave_namespace(ns, "alice", "root") == ["proj-x", "root", "team-a"]
assert mod.member_groups(ns, "alice") == []
assert mod.member_groups(ns, "bob") == ["team-b"]

ns2 = mod.load_namespace(
    ["hub", "left", "right", "sink"],
    [("hub", "left"), ("hub", "right"), ("left", "sink"), ("right", "sink")],
    [("hub", "u"), ("sink", "u"), ("left", "u")],
)
assert mod.scopes_for_member(ns2, "u", "hub") == ["hub", "left", "sink"]
removed = mod.leave_namespace(ns2, "u", "hub")
assert removed == ["hub", "left", "sink"]
print("ok")
