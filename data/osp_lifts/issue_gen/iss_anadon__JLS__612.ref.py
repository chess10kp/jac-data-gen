"""Reference harness for iss_anadon__JLS__612."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_anadon__JLS__612.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_anadon__JLS__612.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

load_dig_workflow = _mod.load_dig_workflow
transitive_dependencies = _mod.transitive_dependencies
downstream_tasks = _mod.downstream_tasks
dependency_paths = _mod.dependency_paths
preserved_test_vectors = _mod.preserved_test_vectors

g = load_dig_workflow(
    [("root", []), ("left", []), ("right", []), ("join", [])],
    [("root", "left"), ("root", "right"), ("left", "join"), ("right", "join")],
)
assert transitive_dependencies(g, "root") == ["join", "left", "right"]
assert transitive_dependencies(g, "join") == []

g = load_dig_workflow(
    [("hub", []), ("mid_a", []), ("mid_b", []), ("leaf", [])],
    [("leaf", "hub"), ("mid_a", "leaf"), ("mid_b", "leaf")],
)
assert downstream_tasks(g, "hub") == ["leaf", "mid_a", "mid_b"]
assert downstream_tasks(g, "mid_a") == []

g = load_dig_workflow([("only", [])], [])
assert transitive_dependencies(g, "missing") == []
assert downstream_tasks(g, "missing") == []
assert dependency_paths(g, "only", "ghost") == []
assert dependency_paths(g, "ghost", "only") == []
assert preserved_test_vectors(g, "ghost") == []
g.add_dependency("only", "ghost")
g.add_dependency("ghost", "only")
assert transitive_dependencies(g, "only") == []

g = load_dig_workflow(
    [("a", []), ("b", []), ("c", [])],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert dependency_paths(g, "a", "a") == [["a"]]
assert dependency_paths(g, "a", "c", max_depth=2) == []
assert dependency_paths(g, "a", "c", max_depth=3) == [["a", "b", "c"]]

g = load_dig_workflow(
    [("a", []), ("b", []), ("c", []), ("d", [])],
    [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")],
)
assert dependency_paths(g, "a", "d") == [["a", "b", "d"], ["a", "c", "d"]]
assert dependency_paths(g, "d", "a") == []

g = load_dig_workflow(
    [("alpha", ["z", "a", "m"]), ("beta", []), ("gamma", ["solo"])],
    [],
)
assert preserved_test_vectors(g, "alpha") == ["a", "m", "z"]
assert preserved_test_vectors(g, "beta") == []
assert preserved_test_vectors(g, "gamma") == ["solo"]
assert preserved_test_vectors(g, "nope") == []

print("iss_anadon__JLS__612 ref OK")
print("iss_anadon__JLS__612 ref OK")
