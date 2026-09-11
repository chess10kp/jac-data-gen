"""Reference harness for iss_Deen-Bridge__dnb-ai__155."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Deen-Bridge__dnb-ai__155.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
store = _mod.load_decomposition_store(
    ["parse", "retrieve", "summarize", "verify", "deliver"],
    [
        ("parse", "retrieve"),
        ("parse", "summarize"),
        ("retrieve", "verify"),
        ("summarize", "verify"),
        ("verify", "deliver"),
    ],
    {
        "parse": "nlp",
        "retrieve": "search",
        "summarize": "nlp",
        "verify": "audit",
        "deliver": "publish",
    },
    {"alpha": ["nlp", "search"], "beta": ["audit", "publish"]},
)
assert _mod.downstream_closure(store, "parse") == [
    "deliver",
    "retrieve",
    "summarize",
    "verify",
]
assert _mod.parallel_waves(store) == [
    ["parse"],
    ["retrieve", "summarize"],
    ["verify"],
    ["deliver"],
]
assert _mod.ready_after(store, []) == ["parse"]
assert _mod.ready_after(store, ["parse"]) == ["retrieve", "summarize"]
assert _mod.ready_after(store, ["parse", "retrieve", "summarize"]) == ["verify"]
assignment = _mod.match_agents(store)
assert assignment == {
    "deliver": "beta",
    "parse": "alpha",
    "retrieve": "alpha",
    "summarize": "alpha",
    "verify": "beta",
}
assert _mod.coverage_ratio(store, assignment) == 1.0
assert _mod.has_dependency_cycle(store) is False

diamond = _mod.load_decomposition_store(
    ["hub", "left", "right", "leaf"],
    [
        ("right", "leaf"),
        ("left", "leaf"),
        ("hub", "right"),
        ("hub", "left"),
    ],
)
assert _mod.downstream_closure(diamond, "hub") == ["leaf", "left", "right"]
assert _mod.parallel_waves(diamond) == [["hub"], ["left", "right"], ["leaf"]]

cycle = _mod.load_decomposition_store(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert _mod.has_dependency_cycle(cycle) is True
assert _mod.parallel_waves(cycle) == []
assert _mod.downstream_closure(cycle, "a") == ["b", "c"]
assert _mod.ready_after(cycle, []) == []

assert _mod.downstream_closure(store, "missing") == []
assert _mod.ready_after(store, ["missing"]) == ["parse"]
assert _mod.coverage_ratio(store, {"parse": "alpha"}) == 0.2
empty = _mod.load_decomposition_store([], [], {}, {})
assert _mod.coverage_ratio(empty, {}) == 1.0
assert _mod.parallel_waves(empty) == []
assert _mod.match_agents(empty) == {}
assert _mod.has_dependency_cycle(empty) is False
print("iss_Deen-Bridge__dnb-ai__155 ref OK")
