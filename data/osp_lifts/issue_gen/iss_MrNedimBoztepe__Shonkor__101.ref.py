import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("iss_MrNedimBoztepe__Shonkor__101", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

EDGES = [("api", "core"), ("web", "api"), ("batch", "core")]
PARENTS = {"api": "core", "web": "api", "core": "stdlib"}

assert mod.blast_radius("core", EDGES) == ["api", "batch", "core", "web"]
assert mod.provenance_chain("web", PARENTS) == ["web", "api", "core", "stdlib"]
assert mod.blast_radius("missing", EDGES) == []
print("ok")
