"""Reference harness for iss_BeardedSheeep__assesment-socgen__4."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_BeardedSheeep__assesment-socgen__4.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

g = _mod.load_layers(
    ["base", "deps", "app_copy", "final"],
    [("base", "deps"), ("deps", "app_copy"), ("app_copy", "final")],
)
assert _mod.invalidated_by(g, "deps") == ["app_copy", "final"]

print("iss_BeardedSheeep__assesment-socgen__4 ref OK")
