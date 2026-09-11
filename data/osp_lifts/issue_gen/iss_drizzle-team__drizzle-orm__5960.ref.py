import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_drizzle-team__drizzle-orm__5960",
    Path(__file__).with_name("iss_drizzle-team__drizzle-orm__5960.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

LINEAR = mod.load_mig_graph(
    ["a", "b", "c"],
    {"a": ["b"], "b": ["c"]},
)
assert mod.collect_leaves(LINEAR, "a") == ["c"]
assert mod.distinct_leaf_count(LINEAR, "a") == 1

DIAMOND = mod.load_mig_graph(
    ["root", "l", "r", "leaf"],
    {"root": ["l", "r"], "l": ["leaf"], "r": ["leaf"]},
)
assert mod.collect_leaves(DIAMOND, "root") == ["leaf"]
assert mod.distinct_leaf_count(DIAMOND, "root") == 1

FORK = mod.load_mig_graph(
    ["base", "b1", "b2", "e1", "e2"],
    {"base": ["b1", "b2"], "b1": ["e1"], "b2": ["e2"]},
)
assert mod.collect_leaves(FORK, "base") == ["e1", "e2"]
assert mod.distinct_leaf_count(FORK, "base") == 2

assert mod.collect_leaves(LINEAR, "missing") == []
print("ok")
