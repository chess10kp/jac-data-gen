import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_rizinorg__rizin__6181",
    Path(__file__).with_name("iss_rizinorg__rizin__6181.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

G = mod.load_graph(
    ["main", "parse", "analyze", "emit", "optimize"],
    [
        ("main", "parse"),
        ("parse", "analyze"),
        ("analyze", "emit"),
        ("analyze", "optimize"),
        ("optimize", "emit"),
    ],
)
assert mod.reachable_from(G, "main") == ["analyze", "emit", "main", "optimize", "parse"]
assert mod.has_path(G, "main", "emit") is True
assert mod.has_path(G, "emit", "main") is False
assert mod.reachable_from(G, "missing") == []
print("ok")
