"""Reference harness for iss_DanielMSchmidt__cfast__305."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_DanielMSchmidt__cfast__305.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

reg = _mod.load_folders(
    {"root": None, "team": "root", "docs": "team"},
    {"root": "workspace", "team": "inherit", "docs": "inherit"},
)
assert _mod.effective_visibility(reg, "docs") == "workspace"
assert _mod.ancestor_folders(reg, "docs") == ["root", "team", "docs"]

print("iss_DanielMSchmidt__cfast__305 ref OK")
