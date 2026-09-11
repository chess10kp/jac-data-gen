import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

r = mod.DocRegistry()
for d in ["TXS-001", "TXS-000", "TXS-LEGACY"]:
    r.register(d)
r.supersedes("TXS-001", "TXS-000")
r.supersedes("TXS-000", "TXS-LEGACY")
assert r.lineage("TXS-001") == ["TXS-000", "TXS-001", "TXS-LEGACY"]
assert r.find_cycle() == []

r2 = mod.DocRegistry()
for d in ["a", "b", "c"]:
    r2.register(d)
r2.supersedes("a", "b")
r2.supersedes("b", "c")
r2.supersedes("c", "a")
assert sorted(set(r2.find_cycle())) == ["a", "b", "c"]
print("ok")
