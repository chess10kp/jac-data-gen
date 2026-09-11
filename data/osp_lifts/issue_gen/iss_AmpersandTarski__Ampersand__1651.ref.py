import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_ampersand_1651",
    Path(__file__).with_name("iss_AmpersandTarski__Ampersand__1651.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

G = mod.load_relation(
    ["a", "b", "c", "d"],
    [("a", "b"), ("b", "c"), ("a", "d")],
)
assert mod.kleene_plus(G, "a") == ["b", "c", "d"]
assert mod.kleene_star(G, "a") == ["a", "b", "c", "d"]
assert mod.has_path(G, "a", "c") is True
assert mod.has_path(G, "c", "a") is False

DIAMOND = mod.load_relation(
    ["s", "x", "y", "t"],
    [("s", "x"), ("s", "y"), ("x", "t"), ("y", "t")],
)
assert mod.kleene_plus(DIAMOND, "s") == ["t", "x", "y"]

assert mod.kleene_plus(G, "missing") == []
print("ok")
