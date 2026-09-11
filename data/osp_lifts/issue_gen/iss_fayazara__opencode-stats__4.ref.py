"""Reference harness for iss_fayazara__opencode-stats__4."""

import importlib.util
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "opencode_stats_4",
    HERE / "iss_fayazara__opencode-stats__4.py",
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

load_sessions = mod.load_sessions
session_costs = mod.session_costs
roots_only_cost = mod.roots_only_cost
total_cost = mod.total_cost
all_session_ids = mod.all_session_ids

STORE = load_sessions(
  # main=100, sub1=80, sub2=70 — buggy path counts only main (100).
    sessions=[
        ("main", 100, 1000),
        ("sub1", 80, 800),
        ("sub2", 70, 700),
        ("orphan", 5, 50),
    ],
    subagents=[("sub1", "main"), ("sub2", "sub1")],
)

assert session_costs(STORE, "main") == (100, 1000)
assert session_costs(STORE, "sub1") == (80, 800)
assert session_costs(STORE, "missing") == (0, 0)
assert roots_only_cost(STORE) == 105  # main + orphan (parent_id IS NULL)
assert total_cost(STORE, "main") == 250
assert all_session_ids(STORE, "main") == ["main", "sub1", "sub2"]
assert total_cost(STORE, "missing") == 0
assert all_session_ids(STORE, "missing") == []

BREADTH = load_sessions(
    sessions=[
        ("root", 10, 100),
        ("w1", 20, 200),
        ("w2", 30, 300),
        ("w3", 40, 400),
        ("deep", 50, 500),
    ],
    subagents=[
        ("w1", "root"),
        ("w2", "root"),
        ("w3", "root"),
        ("deep", "w1"),
    ],
)
assert all_session_ids(BREADTH, "root") == ["deep", "root", "w1", "w2", "w3"]
assert total_cost(BREADTH, "root") == 150

CYCLE = load_sessions(
    sessions=[("a", 1, 10), ("b", 2, 20), ("c", 3, 30)],
    subagents=[("b", "a"), ("c", "b"), ("a", "c")],
)
assert all_session_ids(CYCLE, "b") == ["a", "b", "c"]
assert total_cost(CYCLE, "b") == 6
