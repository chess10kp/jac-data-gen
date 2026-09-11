"""Reference harness for iss_FraOri03__Lattice__202."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_FraOri03__Lattice__202.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

tl = _mod.load_timeline(
    ["src", "fx", "comp", "out"],
    [("src", "fx"), ("fx", "comp"), ("comp", "out")],
)
assert _mod.invalidated_clips(tl, ["src"]) == ["comp", "fx", "out"]
assert _mod.invalidate_cache(tl, "src") == ["comp", "fx", "out", "src"]
assert _mod.is_dirty(tl, "out") is True
assert _mod.is_dirty(tl, "ghost") is False

diamond = _mod.load_timeline(
    ["edit", "a", "b", "mix"],
    [("edit", "a"), ("edit", "b"), ("a", "mix"), ("b", "mix")],
)
assert _mod.invalidated_clips(diamond, ["edit"]) == ["a", "b", "mix"]

print("iss_FraOri03__Lattice__202 ref OK")
