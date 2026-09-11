import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

w = mod.load_world(
    [
        ("world", "root"),
        ("scenario", "scenario"),
        ("agent", "agent"),
        ("tool", "tool"),
    ],
    [
        ("world", "scenario"),
        ("scenario", "agent"),
        ("scenario", "tool"),
    ],
)
assert mod.active_entities(w) == ["agent", "scenario", "tool", "world"]
assert mod.reset_entity(w, "scenario") == ["agent", "scenario", "tool"]
assert mod.active_entities(w) == ["world"]
assert mod.reset_entity(w, "scenario") == []
assert mod.reset_entity(w, "missing") == []

w2 = mod.load_world(
    [("root", "r"), ("left", "l"), ("right", "r"), ("base", "b")],
    [("root", "left"), ("root", "right"), ("left", "base"), ("right", "base")],
)
assert mod.reset_entity(w2, "root") == ["base", "left", "right", "root"]
assert mod.active_entities(w2) == []
print("ok")
