import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_imrohitagrawal__narratwin-ai__435",
    Path(__file__).with_name("iss_imrohitagrawal__narratwin-ai__435.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

GOV = mod.load_phase_graph(
    ["bounds", "parse", "schema", "trust", "auth", "graph", "verdict"],
    [
        ("bounds", "parse"),
        ("parse", "schema"),
        ("schema", "trust"),
        ("trust", "auth"),
        ("auth", "graph"),
        ("graph", "verdict"),
    ],
)
assert mod.upstream_phases(GOV, "verdict") == [
    "auth",
    "bounds",
    "graph",
    "parse",
    "schema",
    "trust",
    "verdict",
]
assert mod.ready_phases(GOV, []) == ["bounds"]
assert mod.ready_phases(GOV, ["bounds", "parse", "schema"]) == ["trust"]
assert mod.upstream_phases(GOV, "missing") == []
print("ok")
