"""Reference harness for iss_AtyaLibraries__Messaging.Outbox__5."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_AtyaLibraries__Messaging_Outbox__5.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
store = _mod.load_outbox_store(
    [
        ("msg_006", "ATYA-006", 1, "published"),
        ("msg_057", "ATYA-057", 1, "published"),
        ("msg_059", "ATYA-059", 1, "pending"),
        ("msg_058", "ATYA-058", 2, "pending"),
        ("msg_poison", "Poison.Event", 1, "pending"),
    ],
    [
        ("msg_058", "msg_059"),
        ("msg_058", "msg_057"),
        ("msg_058", "msg_006"),
        ("msg_059", "msg_006"),
    ],
    next_attempt={"msg_poison": 5},
)

assert _mod.prerequisite_closure(store, "msg_058") == ["msg_006", "msg_057", "msg_059"]
assert _mod.prerequisite_closure(store, "missing") == []

assert _mod.dependency_paths(store, "msg_058", "msg_006") == [
    ["msg_058", "msg_006"],
    ["msg_058", "msg_059", "msg_006"],
]
assert _mod.dependency_paths(store, "msg_058", "msg_006", max_depth=2) == [["msg_058", "msg_006"]]
assert _mod.dependency_paths(store, "ghost", "msg_006") == []

assert _mod.blocked_by(store, "msg_058") == ["msg_059"]
assert _mod.blocked_by(store, "msg_006") == []
assert _mod.blocked_by(store, "ghost") == []

assert _mod.stable_identity(store, "msg_058") == ("ATYA-058", 2)
assert _mod.stable_identity(store, "ghost") == ("", 0)

assert _mod.claimable_ids(store, "relay-a", tick=10) == ["msg_059", "msg_poison"]
assert _mod.claim_batch(store, "relay-a", ["msg_poison", "msg_059"], tick=10) == [
    "msg_059",
    "msg_poison",
]
assert _mod.claim_batch(store, "relay-b", ["msg_059"], tick=10) == []
assert _mod.claimable_ids(store, "relay-b", tick=10) == []

na = _mod.record_failure(store, "msg_poison", tick=10, diag="timeout row read")
assert na == 12
assert _mod.claimable_ids(store, "relay-a", tick=11) == []

cyc = _mod.load_outbox_store(
    [
        ("a", "Cycle.A", 1, "pending"),
        ("b", "Cycle.B", 1, "pending"),
        ("c", "Cycle.C", 1, "pending"),
    ],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert _mod.prerequisite_closure(cyc, "a") == ["b", "c"]
assert _mod.dependency_paths(cyc, "a", "c") == [["a", "b", "c"]]

diamond = _mod.load_outbox_store(
    [
        ("root", "Root", 1, "pending"),
        ("left", "Left", 1, "published"),
        ("right", "Right", 1, "published"),
        ("base", "Base", 1, "published"),
    ],
    [
        ("root", "right"),
        ("root", "left"),
        ("left", "base"),
        ("right", "base"),
    ],
)
assert _mod.prerequisite_closure(diamond, "root") == ["base", "left", "right"]
assert _mod.dependency_paths(diamond, "root", "base") == [
    ["root", "left", "base"],
    ["root", "right", "base"],
]
print("iss_AtyaLibraries__Messaging.Outbox__5 ref OK")
