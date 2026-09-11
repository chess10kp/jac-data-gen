import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_cove_471",
    Path(__file__).with_name("iss_kagura-agent__cove__471.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

b = mod.load_workflow(
    ["collect", "analyze", "debate", "decide"],
    [("collect", "analyze"), ("analyze", "debate"), ("debate", "decide")],
)
assert mod.ready_tasks(b) == ["collect"]
mod.mark_done(b, "collect")
assert mod.ready_tasks(b) == ["analyze"]

b2 = mod.load_workflow(
    ["setup", "integration", "report"],
    [("setup", "integration"), ("integration", "report")],
)
assert mod.mark_failed(b2, "setup") == ["integration", "report"]
print("ok")
