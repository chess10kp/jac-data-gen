import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_the-static-collective__the-haunted-toaster__121",
    Path(__file__).with_name("iss_the-static-collective__the-haunted-toaster__121.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

G = mod.load_receipt_graph(
    ["render", "source_a", "source_b", "spec", "primitive"],
    [
        ("source_a", "render"),
        ("source_b", "render"),
        ("spec", "render"),
        ("primitive", "source_a"),
        ("primitive", "source_b"),
    ],
)
assert mod.dependency_closure(G, "render") == [
    "primitive", "render", "source_a", "source_b", "spec",
]
assert mod.unresolved(G, ["primitive"]) == ["source_a", "source_b", "spec"]
assert mod.unresolved(G, ["primitive", "source_a", "source_b", "spec"]) == ["render"]
assert mod.dependency_closure(G, "ghost") == []
print("ok")
