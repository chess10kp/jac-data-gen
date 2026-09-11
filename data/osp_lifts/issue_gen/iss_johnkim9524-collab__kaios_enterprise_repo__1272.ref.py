import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_johnkim9524-collab__kaios_enterprise_repo__1272",
    Path(__file__).with_name("iss_johnkim9524-collab__kaios_enterprise_repo__1272.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_trust_graph(
    ["portal", "store", "proof", "schema", "escape"],
    [
        ("portal", "store"),
        ("portal", "proof"),
        ("proof", "schema"),
        ("escape", "portal"),
    ],
)
roots = ["portal", "store", "proof", "schema"]
assert mod.dependency_closure(g, roots) == ["portal", "proof", "schema", "store"]
assert mod.rejects_escape(g, roots, "escape") is True
assert mod.rejects_escape(g, roots, "schema") is False

print("ok")
