import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_sergipalomas__autosubmit-api__1",
    Path(__file__).with_name("iss_sergipalomas__autosubmit-api__1.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

EXP = mod.load_job_graph(
    ["setup", "chunk_a", "chunk_b", "merge", "report"],
    [
        ("setup", "chunk_a"),
        ("setup", "chunk_b"),
        ("chunk_a", "merge"),
        ("chunk_b", "merge"),
        ("merge", "report"),
    ],
)
assert mod.critical_predecessors(EXP, "report") == [
    "chunk_a", "chunk_b", "merge", "report", "setup",
]
assert mod.ready_jobs(EXP, []) == ["setup"]
assert mod.ready_jobs(EXP, ["setup", "chunk_a", "chunk_b"]) == ["merge"]
assert mod.critical_predecessors(EXP, "ghost") == []
print("ok")
