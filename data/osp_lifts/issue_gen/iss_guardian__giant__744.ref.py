import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_giant_744",
    Path(__file__).with_name("iss_guardian__giant__744.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

t = mod.load_workspace([
    ("ws", None, True),
    ("docs", "ws", True),
    ("images", "ws", True),
    ("2024", "docs", False),
])
assert mod.expandable_folders(t) == ["docs", "images", "ws"]
assert mod.mark_loaded(t, ["ws"]) == ["ws"]
assert mod.loaded_children(t, "ws") == []
assert mod.expandable_folders(t) == ["docs", "images"]
assert mod.ancestor_path(t, "2024") == ["ws", "docs", "2024"]
print("ok")
