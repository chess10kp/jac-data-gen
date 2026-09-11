"""Reference harness for iss_anthropics__claude-code__84136."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_anthropics__claude-code__84136.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_anthropics__claude-code__84136.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

load_pkg_graph = _mod.load_pkg_graph
transitive_deps = _mod.transitive_deps
install_order = _mod.install_order
cold_start_seconds = _mod.cold_start_seconds
initialize_status = _mod.initialize_status
dependency_paths = _mod.dependency_paths

g = load_pkg_graph(
    [("root", 1.0), ("left", 1.0), ("right", 1.0), ("shared", 1.0), ("leaf", 1.0)],
    [
        ("root", "left"),
        ("root", "right"),
        ("left", "shared"),
        ("right", "shared"),
        ("shared", "leaf"),
    ],
)
assert transitive_deps(g, "root") == ["leaf", "left", "right", "shared"]
assert install_order(g, "root") == ["leaf", "shared", "left", "right", "root"]

g = load_pkg_graph(
    [("a", 1.0), ("b", 2.0)],
    [("a", "b"), ("a", "ghost"), ("phantom", "b"), ("phantom", "a")],
)
assert transitive_deps(g, "a") == ["b"]
assert install_order(g, "a") == ["b", "a"]
assert dependency_paths(g, "a", "ghost") == []
assert dependency_paths(g, "phantom", "b") == []

g = load_pkg_graph([("x", 4.0)], [])
assert install_order(g, "missing") == []
assert transitive_deps(g, "missing") == []
assert cold_start_seconds(g, "missing") == 0.0
assert dependency_paths(g, "missing", "x") == []
assert dependency_paths(g, "x", "missing") == []
assert initialize_status(g, "missing") == "cancelled"

g = load_pkg_graph(
    [("a", 30.0), ("b", 30.0)],
    [("a", "b")],
)
assert initialize_status(g, "a", deadline=60.0) == "ready"
assert initialize_status(g, "a", deadline=59.0) == "cancelled"

g = load_pkg_graph(
    [("a", 0.0), ("b", 0.0), ("c", 0.0), ("s", 0.0), ("t", 0.0), ("u", 0.0)],
    [("a", "b"), ("b", "c"), ("c", "a"), ("s", "t"), ("t", "u")],
)
assert dependency_paths(g, "a", "c") == [["a", "b", "c"]]
assert dependency_paths(g, "s", "u", max_depth=2) == []
assert dependency_paths(g, "s", "u", max_depth=3) == [["s", "t", "u"]]

print("iss_anthropics__claude-code__84136 ref OK")
print("iss_anthropics__claude-code__84136 ref OK")
