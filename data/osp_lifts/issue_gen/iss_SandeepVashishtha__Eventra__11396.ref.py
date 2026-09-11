"""Reference harness for iss_SandeepVashishtha__Eventra__11396."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_SandeepVashishtha__Eventra__11396.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
G = _mod.load_workflow_cache_graph(
    [
        ("checkout", "sha-checkout"),
        ("install", "sha-lock"),
        ("lint", "sha-lock"),
        ("test", "sha-lock"),
        ("build", "sha-lock"),
    ],
    [
        ("install", "checkout"),
        ("lint", "install"),
        ("test", "install"),
        ("build", "test"),
        ("build", "lint"),
    ],
)

assert _mod.cache_key(G, "install") == "install::sha-lock"
assert _mod.cache_key(G, "missing") == ""

assert _mod.memo_ancestors(G, "build") == ["checkout", "install", "lint", "test"]
assert _mod.memo_ancestors(G, "install") == ["checkout"]
assert _mod.memo_ancestors(G, "checkout") == []
assert _mod.memo_ancestors(G, "ghost") == []
assert _mod.memo_ancestors(G, "build") == _mod.memo_ancestors(G, "build")

assert _mod.restore_order(G, "build") == ["checkout", "install", "lint", "test"]
assert _mod.restore_order(G, "checkout") == []
assert _mod.restore_order(G, "ghost") == []

DIAMOND = _mod.load_workflow_cache_graph(
    [("root", "h0"), ("left", "h1"), ("right", "h1"), ("join", "h2")],
    [
        ("join", "right"),
        ("join", "left"),
        ("left", "root"),
        ("right", "root"),
    ],
)
assert _mod.memo_ancestors(DIAMOND, "join") == ["left", "right", "root"]
assert _mod.restore_order(DIAMOND, "join") == ["root", "left", "right"]

ADV = _mod.load_workflow_cache_graph(
    [("r", "h0"), ("a", "h1"), ("b", "h1"), ("c", "h2"), ("d", "h3")],
    [
        ("b", "r"),
        ("a", "r"),
        ("c", "a"),
        ("c", "b"),
        ("d", "c"),
    ],
)
assert _mod.memo_ancestors(ADV, "d") == ["a", "b", "c", "r"]
assert _mod.restore_order(ADV, "d") == ["r", "a", "b", "c"]

assert _mod.downstream_jobs(G, ["install"]) == ["build", "lint", "test"]
assert _mod.downstream_jobs(G, ["checkout"]) == ["build", "install", "lint", "test"]
assert _mod.downstream_jobs(G, ["build"]) == []
assert _mod.downstream_jobs(G, ["ghost"]) == []
assert _mod.downstream_jobs(G, []) == []

assert _mod.cache_keys_to_bust(G, ["install"]) == [
    "build::sha-lock",
    "install::sha-lock",
    "lint::sha-lock",
    "test::sha-lock",
]
assert _mod.cache_keys_to_bust(G, ["checkout"]) == [
    "build::sha-lock",
    "checkout::sha-checkout",
    "install::sha-lock",
    "lint::sha-lock",
    "test::sha-lock",
]
assert _mod.cache_keys_to_bust(G, ["ghost"]) == []

CYC = _mod.load_workflow_cache_graph(
    [("a", "h1"), ("b", "h1"), ("c", "h1")],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert _mod.memo_ancestors(CYC, "a") == ["b", "c"]
assert _mod.downstream_jobs(CYC, ["a"]) == ["b", "c"]
assert _mod.cache_keys_to_bust(CYC, ["a"]) == ["a::h1", "b::h1", "c::h1"]
print("iss_SandeepVashishtha__Eventra__11396 ref OK")
