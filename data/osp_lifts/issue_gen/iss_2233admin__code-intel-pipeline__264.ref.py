import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

idx = mod.load_index(
    ["symbols", "refs", "types", "callgraph", "index"],
    [
        ("refs", "symbols"),
        ("types", "symbols"),
        ("callgraph", "refs"),
        ("callgraph", "types"),
        ("index", "callgraph"),
    ],
)
assert idx.ancestors("index") == ["callgraph", "refs", "symbols", "types"]
assert idx.reachable("index") == ["callgraph", "index", "refs", "symbols", "types"]
assert idx.ancestors("missing") == []
assert idx.reachable("missing") == []
print("ok")
