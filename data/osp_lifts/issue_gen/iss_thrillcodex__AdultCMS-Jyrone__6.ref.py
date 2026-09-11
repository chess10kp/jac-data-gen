import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_thrillcodex__AdultCMS-Jyrone__6",
    Path(__file__).with_name("iss_thrillcodex__AdultCMS-Jyrone__6.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.CategoryStore()
store.add_category("root")
store.add_category("videos", parent="root")
store.add_category("featured", parent="root")
store.add_category("shorts", parent="videos")
store.add_category("clips", parent="featured")
assert store.active_categories() == ["clips", "featured", "root", "shorts", "videos"]
assert store.cascade_delete("videos") == ["shorts", "videos"]
assert store.active_categories() == ["clips", "featured", "root"]
try:
    store.cascade_delete("ghost")
    raise AssertionError("expected KeyError")
except KeyError:
    pass
print("ok")
