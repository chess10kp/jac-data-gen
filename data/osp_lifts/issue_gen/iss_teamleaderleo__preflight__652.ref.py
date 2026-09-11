import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_teamleaderleo__preflight__652",
    Path(__file__).with_name("iss_teamleaderleo__preflight__652.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

TREE = mod.load_release_tree(
    ["source", "benchmark", "desktop", "signing", "beta"],
    [
        ("source", "benchmark"),
        ("benchmark", "desktop"),
        ("desktop", "signing"),
        ("signing", "beta"),
    ],
)
assert mod.blocking_chain(TREE, "beta") == ["source", "benchmark", "desktop", "signing", "beta"]
assert mod.next_unlocked(TREE, []) == ["source"]
assert mod.next_unlocked(TREE, ["source", "benchmark"]) == ["desktop"]
assert mod.blocking_chain(TREE, "missing") == []
print("ok")
