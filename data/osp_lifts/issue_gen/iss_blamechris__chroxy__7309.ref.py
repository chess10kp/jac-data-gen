"""Reference harness for iss_blamechris__chroxy__7309."""

import importlib.util
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "chroxy7309",
    HERE / "iss_blamechris__chroxy__7309.py",
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

load_sessions = mod.load_sessions
search = mod.search
lineage = mod.lineage
descendants = mod.descendants
search_scoped = mod.search_scoped

STORE = load_sessions(
    sessions=[
        ("s1", "proj-a", "openai"),
        ("s2", "proj-a", "openai"),
        ("s3", "proj-b", "anthropic"),
        ("s4", "proj-a", "openai"),
    ],
    forks=[("s2", "s1"), ("s4", "s2")],
    subagents=[("s3", "s1")],
    messages=[
        ("s1", "user", "deploy indexed session query"),
        ("s2", "user", "fork discussion about deploy"),
        ("s4", "user", "nested fork thread"),
    ],
    live=[("s1", "assistant", "live tail about indexing now")],
)

assert search(STORE, "indexing") == ["s1"]
assert search(STORE, "deploy") == ["s1", "s2"]
assert search(STORE, "deploy", project="proj-b") == []
assert search(STORE, "deploy", role="user") == ["s1", "s2"]
assert lineage(STORE, "s4") == ["s1", "s2"]
assert descendants(STORE, "s1") == ["s2", "s3", "s4"]
assert search_scoped(STORE, "discussion", "s1") == ["s2"]
assert search_scoped(STORE, "nested", "s1") == ["s4"]
assert lineage(STORE, "missing") == []
assert descendants(STORE, "missing") == []
assert search(STORE, "ghost") == []

CYCLE = load_sessions(
    sessions=[("a", "p", "x"), ("b", "p", "x"), ("c", "p", "x")],
    forks=[("b", "a"), ("c", "b"), ("a", "c")],
    subagents=[],
    messages=[],
    live=[],
)
assert lineage(CYCLE, "b") == ["a", "c"]
assert descendants(CYCLE, "a") == ["b", "c"]
