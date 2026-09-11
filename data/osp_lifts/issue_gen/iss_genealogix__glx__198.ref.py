import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod198",
    Path(__file__).with_name("iss_genealogix__glx__198.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

arch = mod.load_archive(
    ["john", "mary", "ann", "bob"],
    [("john", "mary"), ("mary", "ann"), ("john", "bob")],
)
assert mod.shortest_path(arch, "ann", "bob") == ["ann", "mary", "john", "bob"]
assert mod.ancestors(arch, "ann", 2) == ["john", "mary"]
assert mod.shortest_path(arch, "ann", "missing") is None
print("ok")
