import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_hades_26",
    Path(__file__).with_name("iss_wardle__hades__26.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_terminology(
    ["snomed:247", "snomed:parent", "icd:E11", "loinc:123"],
    [("snomed:parent", "snomed:247")],
    [("snomed:247", "icd:E11")],
)
assert mod.ancestors_of(g, "snomed:247") == ["snomed:parent"]
assert mod.translations_of(g, "snomed:247") == ["icd:E11"]
assert mod.lookup_path(g, "snomed:247", "icd:") == ["snomed:247", "icd:E11"]
print("ok")
