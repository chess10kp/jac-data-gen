import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_kevin-earl-denny__vibe-code-boilerplate__285",
    Path(__file__).with_name("iss_kevin-earl-denny__vibe-code-boilerplate__285.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

b = mod.load_tickets(
    ["t1", "t2", "t3", "t4", "t5"],
    [("t1", "t2"), ("t2", "t3"), ("t1", "t4"), ("t4", "t5")],
)
assert mod.highlight_chain(b, "t2") == ["t1", "t2", "t3"]
assert mod.highlight_chain(b, "t4") == ["t1", "t4", "t5"]
assert mod.highlight_chain(b, "missing") == []

print("ok")
