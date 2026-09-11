import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_8820",
    Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__8820.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

w = mod.load_world(
    ["parse", "typecheck", "codegen", "emit", "cache"],
    [
        ("typecheck", "parse"),
        ("codegen", "typecheck"),
        ("emit", "codegen"),
        ("emit", "cache"),
    ],
)
assert mod.reverse_invalidation_closure(w, "parse") == [
    "parse",
    "typecheck",
    "codegen",
    "emit",
]
assert mod.classify_transition({"a"}, {"a"}) == "no_change"
assert mod.classify_transition({"a"}, {"a", "b"}) == "public_change"
assert mod.invalidate_for_transition(w, "parse", "no_change") == ["parse"]
assert mod.invalidate_for_transition(w, "codegen", "public_change") == [
    "codegen",
    "emit",
]

w_d = mod.load_world(
    ["hub", "left", "right", "leaf"],
    [("left", "leaf"), ("right", "leaf"), ("hub", "left"), ("hub", "right")],
)
assert sorted(mod.reverse_invalidation_closure(w_d, "leaf")) == [
    "hub",
    "leaf",
    "left",
    "right",
]
print("ok")
