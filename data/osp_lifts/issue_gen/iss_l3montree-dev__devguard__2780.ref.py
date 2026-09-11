"""Reference harness for l3montree-dev/devguard#2780."""

import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
  "dg2780", HERE / "iss_l3montree-dev__devguard__2780.py",
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

COMPONENTS = [
  ("ROOT", "root"),
  ("pkg:a", "lib-a"),
  ("pkg:b", "lib-b"),
  ("pkg:c", "lib-c"),
  ("pkg:shared", "shared"),
]
DEPS = [
  ("ROOT", "pkg:a"),
  ("ROOT", "pkg:b"),
  ("pkg:a", "pkg:c"),
  ("pkg:b", "pkg:shared"),
  ("pkg:c", "pkg:shared"),
]
SOURCES = [
  ("app1", "1.0", "lock.json", "ROOT"),
  ("app2", "1.0", "lock.json", "ROOT"),
]

store = mod.load_sbom(COMPONENTS, DEPS, SOURCES)
assert mod.subtree_hash(store, "pkg:shared") != ""
assert mod.subtree_hash(store, "missing") == ""

new_edges = mod.ingest_edges(store)
assert new_edges == 5
assert mod.ingest_edges(store) == 0

closure = mod.transitive_deps(store, "app1", "1.0", "lock.json")
assert closure == ["ROOT", "pkg:a", "pkg:b", "pkg:c", "pkg:shared"]
assert mod.transitive_deps(store, "missing", "1.0", "x") == []

affected = mod.artifacts_with_component(store, "pkg:shared")
assert affected == [("app1", "1.0", "lock.json"), ("app2", "1.0", "lock.json")]
assert mod.artifacts_with_component(store, "missing") == []

print("ok")
