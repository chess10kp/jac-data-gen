import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_dmc_100",
    Path(__file__).with_name("iss_VrUaCom__dmc-rengine-cpp__100.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_volumes(
    [("pac_root", "PAC"), ("inner", "PNST"), ("leaf", "NBZ")],
    [("pac_root", "inner"), ("inner", "leaf")],
)
assert mod.nested_children(store, "pac_root") == ["inner", "leaf"]
assert mod.materialization_path(store, "leaf") == ["pac_root", "inner", "leaf"]
assert mod.entry_kind(store, "inner") == "PNST"
assert mod.nested_children(store, "missing") == []
print("ok")
