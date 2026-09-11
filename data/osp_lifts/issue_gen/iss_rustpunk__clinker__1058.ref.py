import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_clinker_1058",
    Path(__file__).with_name("iss_rustpunk__clinker__1058.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ps = mod.load_pipeline(
    ["src", "body_in", "body_out", "sink"],
    [("src", "body_in"), ("body_in", "body_out"), ("body_out", "sink")],
    body_nodes=["body_in", "body_out"],
)
assert mod.all_lineage_nodes(ps, "src") == ["body_in", "body_out", "sink", "src"]
assert mod.composition_body_nodes(ps) == ["body_in", "body_out"]
assert mod.missing_binding(ps, "body_in") is False
assert mod.missing_binding(ps, "ghost") is True
print("ok")
