import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_EffortlessMetrics__perl-lsp-swarm__7946",
    Path(__file__).with_suffix(".py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

EDGES = [("src", "ir"), ("ir", "obj"), ("hdr", "obj")]
CACHE = {"src": "s1", "ir": "i1", "obj": "o1", "hdr": "h1"}

assert mod.artifact_closure("src", EDGES) == ["ir", "obj", "src"]
assert mod.dependent_closure("obj", EDGES) == ["hdr", "ir", "obj", "src"]
assert mod.cache_lookup("obj", dict(CACHE)) == "o1"
assert mod.cache_lookup("missing", CACHE) is None

c = dict(CACHE)
got = mod.invalidate_artifact("ir", EDGES, c)
assert sorted(got) == ["hdr", "ir", "obj", "src"]
assert "obj" not in c and "src" not in c
assert mod.artifact_closure("missing", EDGES) == []
print("ok")
