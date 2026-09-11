"""Reference harness for iss_Chris-Wolfgang__repo-template__411."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Chris-Wolfgang__repo-template__411.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

g = _mod.load_packages(
    ["app", "core", "json", "linq"],
    [("app", "core"), ("core", "json"), ("core", "linq")],
)
assert _mod.transitive_deps(g, "app") == ["core", "json", "linq"]

print("iss_Chris-Wolfgang__repo-template__411 ref OK")
