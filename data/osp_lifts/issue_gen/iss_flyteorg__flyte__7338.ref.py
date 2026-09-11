import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod7338",
    Path(__file__).with_name("iss_flyteorg__flyte__7338.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_execution(
    ["root", "lp1", "lp2", "leaf"],
    [("root", "lp1"), ("lp1", "lp2"), ("lp2", "leaf")],
)
assert mod.count_nodes(store, "root") == 4
assert mod.sync_depth(store, "root", 3) is True
assert mod.sync_depth(store, "root", 2) is False
assert mod.max_observed_depth(store, "root") == 3
print("ok")
