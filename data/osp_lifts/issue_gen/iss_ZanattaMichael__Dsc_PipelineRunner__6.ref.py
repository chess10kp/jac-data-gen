import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_ZanattaMichael__Dsc_PipelineRunner__6.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

cfg = mod.load_config([("A", "[ref:B]"), ("B", "[ref:A]")])
try:
    mod.expand_references(cfg)
    raise AssertionError("expected cycle")
except mod.CircularReferenceError:
    pass

cfg2 = mod.load_config(
    [("A", "[ref:B]"), ("B", "[ref:C]"), ("C", "ok"), ("D", "plain")]
)
assert mod.expand_references(cfg2) == {"A": "ok", "B": "ok", "C": "ok", "D": "plain"}
assert mod.reference_chain(cfg2, "A") == ["A", "B", "C"]
print("ok")
