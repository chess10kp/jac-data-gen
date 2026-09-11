import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_seandavi__taxonset-db__8.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_taxonomy(
    [("root", "domain"), ("g1", "genus"), ("s1", "species"), ("s2", "species")],
    [("root", "g1"), ("g1", "s1"), ("g1", "s2")],
)
assert mod.descendants(store, "g1") == ["g1", "s1", "s2"]
assert mod.ancestor_chain(store, "s1") == ["s1", "g1", "root"]
assert mod.taxa_by_rank(store, "root", "species") == ["s1", "s2"]
print("ok")
