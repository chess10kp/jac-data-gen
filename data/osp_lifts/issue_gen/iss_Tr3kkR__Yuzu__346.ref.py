"""Reference harness for Tr3kkR/Yuzu#346."""

import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_Tr3kkR__Yuzu__346", Path(__file__).with_suffix(".py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

GROUPS = [("root", None), ("fleet", "root"), ("team_a", "fleet"), ("team_b", "fleet"), ("pod", "team_a")]
g = mod.load_groups(GROUPS)
assert mod.descendant_ids(g, "fleet") == ["pod", "team_a", "team_b"]
assert mod.ancestor_ids(g, "pod") == ["fleet", "root"]
assert mod.descendant_ids(g, "missing") == []
diamond = mod.load_groups([
    ("hub", None), ("left", "hub"), ("right", "hub"), ("join", "left"), ("join2", "right"),
])
assert mod.descendant_ids(diamond, "hub") == ["join", "join2", "left", "right"]
print("ok")
