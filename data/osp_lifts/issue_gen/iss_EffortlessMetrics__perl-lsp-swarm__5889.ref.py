import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__5889.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_crate_graph(["core", "api", "cli"], [("api", "core"), ("cli", "api")])
assert mod.publish_order(g) == ["core", "api", "cli"]
removed = mod.remove_crate_cascade(g, "core")
assert removed == ["api", "cli", "core"]
print("ok")
