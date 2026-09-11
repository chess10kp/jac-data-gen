import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_openclaw__openclaw__76611",
    Path(__file__).with_name("iss_openclaw__openclaw__76611.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_crypto_store([("root", ["sess"]), ("sess", ["key"])])
mod.mark_dirty(g, "key")
assert mod.pending_persist(g) == ["key", "root", "sess"]
assert mod.flush_dirty(g) == ["key", "root", "sess"]
assert mod.pending_persist(g) == []

g2 = mod.load_crypto_store(
    [("hub", ["a", "b"]), ("a", ["leaf"]), ("b", ["leaf"]), ("leaf", [])],
)
mod.mark_dirty(g2, "leaf")
assert mod.reachable_keys(g2, "hub") == ["a", "b", "hub", "leaf"]
assert mod.flush_dirty(g2) == ["leaf"]
print("ok")
