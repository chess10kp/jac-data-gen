import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_neo4j_2",
    Path(__file__).with_name("iss_Network-Centric-LLC__neo4j-operations__2.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_issue_graph(
    ["epic", "pkg", "driver", "skill"],
    [
        ("epic", "pkg"),
        ("pkg", "driver"),
        ("driver", "skill"),
    ],
    ["epic"],
)
assert mod.ready_issues(g) == ["pkg"]
assert mod.blocked_closure(g, "skill") == ["driver", "epic", "pkg", "skill"]
mod.mark_resolved(g, "pkg")
assert mod.ready_issues(g) == ["driver"]
print("ok")
