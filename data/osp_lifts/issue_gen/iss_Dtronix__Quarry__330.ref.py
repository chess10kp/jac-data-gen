"""Reference harness for iss_Dtronix__Quarry__330."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Dtronix__Quarry__330.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

org = _mod.load_org(
    ["ceo", "vp", "eng1", "eng2", "intern"],
    [("ceo", "vp"), ("vp", "eng1"), ("vp", "eng2"), ("eng1", "intern")],
)
assert _mod.manager_descendants(org, "ceo") == ["eng1", "eng2", "intern", "vp"]
assert _mod.direct_reports(org, "vp") == ["eng1", "eng2"]
assert _mod.reporting_depth(org, "intern") == 3
assert _mod.manager_descendants(org, "missing") == []

print("iss_Dtronix__Quarry__330 ref OK")
