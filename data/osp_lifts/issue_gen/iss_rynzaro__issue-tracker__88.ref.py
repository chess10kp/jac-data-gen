import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_rynzaro__issue-tracker__88",
    Path(__file__).with_name("iss_rynzaro__issue-tracker__88.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

TASKS = ["alpha", "sub1", "sub2", "sub1a", "sibling", "ext"]
OWNERS = {
    "alpha": "alice",
    "sub1": "alice",
    "sub2": "alice",
    "sub1a": "alice",
    "sibling": "alice",
    "ext": "alice",
}
CHILD_OF = [
    ("sub1", "alpha"),
    ("sub2", "alpha"),
    ("sub1a", "sub1"),
    ("sibling", "alpha"),
]
HANDOVERS = [("alice", "bob", "sub1")]
REFS = [("sub1a", "sub2"), ("sub1", "ext")]

board = mod.build_board(TASKS, OWNERS, CHILD_OF, HANDOVERS, REFS)

assert mod.handed_subtree(board, "sub1") == ["sub1", "sub1a"]
assert mod.handed_subtree(board, "missing") == []
assert mod.visible_roots(board, "bob") == ["sub1"]
assert mod.visible_roots(board, "alice") == ["alpha", "ext"]
assert mod.downstream_order(board, "sub1") == ["sub1", "sub1a"]
assert mod.subtree_reachable(board, "sub1", "sub1a") is True
assert mod.subtree_reachable(board, "sub1", "alpha") is False
assert mod.ref_violations(board, "sub1") == ["sub1->ext"]
assert mod.ref_violations(board, "missing") == []
assert mod.hander_for(board, "sub1") == "alice"
assert mod.hander_for(board, "alpha") is None
assert mod.can_see_hander(board, "sub1", "bob") is True
assert mod.can_see_hander(board, "sub1", "alice") is False

board2 = mod.build_board(
    ["hub", "left", "right", "sink"],
    {"hub": "alice", "left": "alice", "right": "alice", "sink": "alice"},
    [("left", "hub"), ("right", "hub"), ("sink", "left"), ("sink", "right")],
    [],
    [("sink", "left")],
)
assert mod.handed_subtree(board2, "hub") == ["hub", "left", "right", "sink"]
assert mod.ref_violations(board2, "hub") == []

board3 = mod.build_board(
    ["a", "b", "c", "d"],
    {"a": "alice", "b": "alice", "c": "alice", "d": "alice"},
    [("b", "a"), ("c", "b"), ("a", "c"), ("d", "c")],
    [],
    [],
)
assert mod.handed_subtree(board3, "a") == ["a", "b", "c", "d"]

print("ok")
