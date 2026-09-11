import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_khalilbenaz__khalilbenaz_github_io__214",
    Path(__file__).with_name("iss_khalilbenaz__khalilbenaz_github_io__214.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_people(
    ["Khalil", "Parent", "Grandparent"],
    [("Khalil", "Parent"), ("Parent", "Grandparent")],
)
assert mod.ancestors_of(store, "Khalil") == ["Grandparent", "Parent"]
assert mod.is_ancestor(store, "Parent", "Khalil") is True
assert mod.parent_of(store, "Khalil") == "Parent"
assert mod.ancestors_of(store, "Grandparent") == []
print("ok")
