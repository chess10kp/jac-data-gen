import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_service_lasso_878",
    Path(__file__).with_name("iss_service-lasso__service-lasso__878.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_runtime_graph(
    ["api", "worker", "ui"],
    [("api", "worker"), ("api", "ui")],
    {"api": "8080", "worker": "8080", "ui": "8080"},
)
assert mod.impacted_consumers(g, "api") == ["ui", "worker"]
changed = mod.propagate_endpoint(g, "api", "9090")
assert changed == ["api", "ui", "worker"]
assert mod.active_endpoints(g) == {"api": "9090", "ui": "9090", "worker": "9090"}

g2 = mod.load_runtime_graph(["solo"], [], {"solo": "3000"})
assert mod.propagate_endpoint(g2, "solo", "3001") == ["solo"]
print("ok")
