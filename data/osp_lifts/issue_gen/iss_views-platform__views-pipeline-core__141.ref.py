import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_views-platform__views-pipeline-core__141",
    Path(__file__).with_name("iss_views-platform__views-pipeline-core__141.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

PIPE = mod.load_pipeline(
    ["136", "137", "139", "140", "141"],
    [
        ("136", "141"),
        ("137", "141"),
        ("139", "141"),
        ("140", "141"),
    ],
)
assert mod.all_prerequisites(PIPE, "141") == ["136", "137", "139", "140", "141"]
assert mod.runnable_stages(PIPE, []) == ["136", "137", "139", "140"]
assert mod.runnable_stages(PIPE, ["136", "137", "139", "140"]) == ["141"]

assert mod.all_prerequisites(PIPE, "missing") == []
print("ok")
