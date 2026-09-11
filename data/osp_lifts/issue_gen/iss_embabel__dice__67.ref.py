import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_embabel__dice__67",
    Path(__file__).with_name("iss_embabel__dice__67.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_runs(
    [("r1", "t1"), ("r2", "t1"), ("r3", "t1"), ("r4", "t2")],
    [("r2", "r1"), ("r3", "r2")],
    [("r1", "r4")],
    [("r3", "failed")],
)
assert mod.parent_lineage(store, "r3") == ["r1", "r2"]
assert mod.superseded_chain(store, "r1") == ["r4"]
assert mod.would_create_parent_cycle(store, "r1", "r3") is True
assert mod.runs_for_tenant(store, "t1") == ["r1", "r2", "r3"]
assert mod.run_status(store, "r3") == "failed"

store2 = mod.load_runs([("a", "t"), ("b", "t")], [("a", "b"), ("b", "a")], [], [])
try:
    mod.set_parent(store2, "a", "b")
    raise AssertionError("expected cycle rejection")
except ValueError:
    pass
print("ok")
