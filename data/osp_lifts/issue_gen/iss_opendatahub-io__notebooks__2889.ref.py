"""Reference harness for iss_opendatahub-io__notebooks__2889."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_opendatahub-io__notebooks__2889.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
from pathlib import Path

_mod_path = Path(__file__).with_name("iss_opendatahub-io__notebooks__2889.py")
_spec = importlib.util.spec_from_file_location("issue2889", _mod_path)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

build_graph = _mod.build_graph
missing_lock_dependencies = _mod.missing_lock_dependencies
parse_lock_packages = _mod.parse_lock_packages
walk_dependency_order = _mod.walk_dependency_order

pkgs_missing: list = [
    {"name": "kfp", "deps": ["docstring-parser", "requests-toolbelt"]},
    {"name": "docstring-parser", "deps": []},
]
assert missing_lock_dependencies(pkgs_missing) == [["kfp", "requests-toolbelt"]]

pkgs_adj: list = [
    {"name": "b", "deps": ["a"]},
    {"name": "a", "deps": []},
]
assert parse_lock_packages(pkgs_adj) == {"a": [], "b": ["a"]}

pkgs_chain: list = [
    {"name": "app", "deps": ["lib"]},
    {"name": "lib", "deps": []},
]
assert walk_dependency_order(pkgs_chain, "app") == ["app", "lib"]

pkgs_unknown: list = [{"name": "only", "deps": []}]
assert walk_dependency_order(pkgs_unknown, "ghost") == []

pkgs_diamond: list = [
    {"name": "root", "deps": ["x", "y"]},
    {"name": "x", "deps": ["shared"]},
    {"name": "shared", "deps": []},
    {"name": "y", "deps": ["shared"]},
]
assert walk_dependency_order(pkgs_diamond, "root") == ["root", "x", "shared", "y"]

pkgs_empty: list = [{"name": "solo", "deps": []}]
assert missing_lock_dependencies(pkgs_empty) == []

store = build_graph([{"name": "solo", "deps": []}])
assert "solo" in store
assert store["solo"].name == "solo"
assert store["solo"].cid == "solo"
print("iss_opendatahub-io__notebooks__2889 ref OK")
