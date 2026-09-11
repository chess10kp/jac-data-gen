import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

EDGES = [("root", "a"), ("a", "b"), ("b", "c")]
DEPS = [("app", "lib"), ("lib", "core")]

assert mod.evidence_reachable("root", EDGES, 3) == ["root", "a", "b"]
assert mod.summarize_assertions(["z", "a", "m"], 2) == ["a", "m"]
assert mod.transitive_evidence("app", DEPS) == ["app", "core", "lib"]
print("ok")
