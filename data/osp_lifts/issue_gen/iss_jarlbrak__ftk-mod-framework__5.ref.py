import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_jarlbrak__ftk-mod-framework__5",
    Path(__file__).with_name("iss_jarlbrak__ftk-mod-framework__5.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

CAMPAIGN = mod.load_spec_graph(
    ["P1", "P2", "P3", "P5", "POC"],
    [("P1", "P2"), ("P1", "P3"), ("P3", "P2"), ("P2", "POC"), ("P5", "POC")],
)
assert mod.prerequisites(CAMPAIGN, "POC") == ["P1", "P2", "P3", "P5", "POC"]
assert mod.ready_specs(CAMPAIGN, []) == ["P1", "P5"]
assert mod.ready_specs(CAMPAIGN, ["P1", "P5"]) == ["P3"]
assert mod.ready_specs(CAMPAIGN, ["P1", "P3", "P5"]) == ["P2"]

assert mod.prerequisites(CAMPAIGN, "missing") == []
print("ok")
