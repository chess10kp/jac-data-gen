import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_tstapler__stapler-squad__460.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

b = mod.load_backlog(
    ["schema", "ui"],
    [("ui", "schema")],
    [("schema", "in_progress"), ("ui", "ready")],
)
assert mod.is_dequeue_allowed(b, "ui") is False
assert mod.blocked_by_unshipped(b, "ui") == ["schema"]
b._status["schema"] = "shipped"
assert mod.is_dequeue_allowed(b, "ui") is True
print("ok")
