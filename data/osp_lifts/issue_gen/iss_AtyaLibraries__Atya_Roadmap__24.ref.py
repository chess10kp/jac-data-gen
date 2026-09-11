import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_atya_24",
    Path(__file__).with_name("iss_AtyaLibraries__Atya_Roadmap__24.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

m = mod.load_fleet_manifest(
    ["roadmap", "cli", "platform"],
    [("roadmap", "cli"), ("roadmap", "platform"), ("cli", "platform")],
)
assert mod.reachable_repos(m, "roadmap") == ["cli", "platform", "roadmap"]
assert mod.drift_violations(m, [("roadmap", "cli")]) == [
    ("cli", "platform"),
    ("roadmap", "platform"),
]
assert mod.orphan_repos(m, ["roadmap"]) == []
print("ok")
