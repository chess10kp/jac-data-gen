import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_johnjansen_44",
    Path(__file__).with_name("iss_johnjansen__claudeclaw__44.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

b = mod.load_job_board(
    ["build", "test", "deploy"],
    [("build", "test"), ("test", "deploy")],
)
assert mod.get_ready_jobs(b) == ["build"]
assert mod.execution_order(b) == ["build", "test", "deploy"]
assert mod.detect_cycles(b) == []

b2 = mod.load_job_board(["a", "b"], [("a", "b"), ("b", "a")])
assert mod.detect_cycles(b2) == [("b", "a")]
assert mod.execution_order(b2) == []

b3 = mod.load_job_board(
    ["hub", "left", "right", "leaf"],
    [
        ("hub", "left"),
        ("hub", "right"),
        ("left", "leaf"),
        ("right", "leaf"),
    ],
    done=["hub"],
)
assert mod.get_ready_jobs(b3) == ["left", "right"]
print("ok")
