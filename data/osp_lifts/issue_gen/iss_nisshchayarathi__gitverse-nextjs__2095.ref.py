import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_nisshchayarathi__gitverse-nextjs__2095",
    Path(__file__).with_name("iss_nisshchayarathi__gitverse-nextjs__2095.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_modules(
    ["fileA", "fileB", "fileC"],
    [("fileA", "fileB"), ("fileB", "fileC"), ("fileC", "fileA")],
)
assert mod.import_closure(g, "fileA") == ["fileA", "fileB", "fileC"]
assert mod.has_cycle(g) is True

acy = mod.load_modules(["x", "y", "z"], [("x", "y"), ("y", "z")])
assert mod.import_closure(acy, "x") == ["x", "y", "z"]
assert mod.has_cycle(acy) is False

print("ok")
