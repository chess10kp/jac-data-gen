import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_mistersilver-uk__fabricate__1070.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_craft_graph(
    [("steel", "mat"), ("gear", "part"), ("engine", "item"), ("frame", "part")],
    [("engine", "gear"), ("gear", "steel"), ("frame", "steel")],
)
assert mod.reachable_components(g, "engine") == ["engine", "gear", "steel"]
assert mod.components_by_kind(g, "engine", "mat") == ["steel"]
assert mod.invalidate_component(g, "steel") == ["engine", "frame", "gear", "steel"]
print("ok")
