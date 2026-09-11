import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_oxc_16118",
    Path(__file__).with_name("iss_oxc-project__oxc__16118.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_linter(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c")],
    initial_pending=["a"],
)
assert mod.fix_until_stable(g) == [["a", "b", "c"]]
assert mod.reachable_rules(g, "a") == ["b", "c"]
print("ok")
