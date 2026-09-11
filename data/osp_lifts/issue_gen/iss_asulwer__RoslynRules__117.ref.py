import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod117",
    Path(__file__).with_name("iss_asulwer__RoslynRules__117.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_rules(
    [("leaf", "parent"), ("parent", "root"), ("root", None), ("sibling", "root")],
    [("root", "leaf"), ("root", "sibling"), ("parent", "leaf")],
)
assert mod.rule_ancestors(store, "leaf") == ["root", "parent", "leaf"]
assert mod.dependent_rules(store, "root") == ["leaf", "parent", "root", "sibling"]
ticks = {"root": 1, "parent": 2, "leaf": 3, "sibling": 4}
assert mod.profile_self_ms(store, "leaf", ticks) == 3
assert mod.profile_total_ms(store, "root", ticks) == 10
print("ok")
