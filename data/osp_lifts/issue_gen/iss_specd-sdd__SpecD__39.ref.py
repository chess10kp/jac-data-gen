import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_specd-sdd__SpecD__39",
    Path(__file__).with_name("iss_specd-sdd__SpecD__39.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_graph(
    ["login", "auth", "session", "email", "register"],
    [
        ("login", "auth"),
        ("auth", "session"),
        ("register", "auth"),
        ("register", "email"),
    ],
)
assert mod.reachable_flow(g, "login", 3) == ["auth", "login", "session"]
assert mod.process_count(g, ["login", "register"], 2) == 5

print("ok")
