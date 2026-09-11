import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_dasomel__narwhal__110", Path(__file__).with_suffix(".py")
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

EDGES = [("checkout", "payments"), ("payments", "ledger"), ("notify", "payments")]
DEPS = {"checkout": "payments", "payments": "ledger", "ledger": "db"}

assert mod.blast_radius("ledger", EDGES) == ["checkout", "ledger", "notify", "payments"]
assert mod.upstream_chain("checkout", DEPS) == ["checkout", "payments", "ledger", "db"]
assert mod.blast_radius("missing", EDGES) == []
print("ok")
