import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_Apicurio__apicurio-registry__9000",
    Path(__file__).with_name("iss_Apicurio__apicurio-registry__9000.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)
reg = mod.load_registry(
    [
        ("g", "Common", "1", "body-v1"),
        ("g", "Common", "2", "body-v2"),
        ("g", "A", "1", "body-a"),
        ("g", "B", "1", "body-b"),
        ("g", "Main", "1", "body-main"),
    ],
    [
        ("g", "A", "1", "common.avsc", "g", "Common", "1"),
        ("g", "B", "1", "common.avsc", "g", "Common", "2"),
        ("g", "Main", "1", "refA", "g", "A", "1"),
        ("g", "Main", "1", "refB", "g", "B", "1"),
    ],
)
k1 = mod.gav_key("g", "Common", "1")
k2 = mod.gav_key("g", "Common", "2")
root = mod.gav_key("g", "Main", "1")
got = mod.resolve_tree(reg, root)
assert got[k1] == "body-v1"
assert got[k2] == "body-v2"
assert len(got) == 5

reg_c = mod.load_registry(
    [("g", "X", "1", "x"), ("g", "Y", "1", "y")],
    [("g", "X", "1", "r", "g", "Y", "1"), ("g", "Y", "1", "r", "g", "X", "1")],
)
assert len(mod.resolve_tree(reg_c, mod.gav_key("g", "X", "1"))) == 2
print("ok")
