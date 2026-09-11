import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_nickbyrum2469__OmniForge__1",
    Path(__file__).with_name("iss_nickbyrum2469__OmniForge__1.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

BASIC = mod.load_asset_store(
    ["glb", "mesh", "mat"],
    [("glb", "mesh"), ("glb", "mat")],
    [("scene1", "glb")],
)
assert mod.scene_usages(BASIC, "glb") == ["scene1"]
try:
    mod.delete_import(BASIC, "glb")
    raise AssertionError("expected ValueError")
except ValueError:
    pass
assert mod.delete_import(BASIC, "glb", force=True) == ["glb", "mat", "mesh"]
assert mod.active_assets(BASIC) == []

NESTED = mod.load_asset_store(
    ["root", "lod0", "lod1", "thumb"],
    [("root", "lod0"), ("lod0", "lod1"), ("root", "thumb")],
    [],
)
assert mod.delete_import(NESTED, "root") == ["lod0", "lod1", "root", "thumb"]
assert mod.active_assets(NESTED) == []

DIAMOND = mod.load_asset_store(
    ["base", "a", "b", "leaf"],
    [("base", "a"), ("base", "b"), ("a", "leaf"), ("b", "leaf")],
    [],
)
assert mod.delete_import(DIAMOND, "base") == ["a", "b", "base", "leaf"]

assert mod.delete_import(BASIC, "missing") == []
print("ok")
