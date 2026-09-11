"""Reference harness for MemberJunction/MJ#2859."""

import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "mj2859", HERE / "iss_MemberJunction__MJ__2859.py",
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ENTITIES = [
    ("field:name", "EntityField"),
    ("field:email", "EntityField"),
    ("action:save", "Action"),
    ("agent:crm", "AIAgent"),
    ("view:customers", "UserView"),
    ("query:all", "Query"),
    ("shared:util", "Template"),
]
EDGES = [
    ("action:save", "field:name"),
    ("action:save", "field:email"),
    ("agent:crm", "action:save"),
    ("view:customers", "field:name"),
    ("view:customers", "query:all"),
    ("query:all", "field:email"),
    ("query:all", "shared:util"),
]

g = mod.load_graph(ENTITIES, EDGES)

assert mod.dependencies(g, "agent:crm") == [
    "action:save", "field:email", "field:name",
]
assert mod.dependents(g, "field:name") == [
    "action:save", "agent:crm", "view:customers",
]
assert mod.path_between(g, "agent:crm", "field:name") == [
    "agent:crm", "action:save", "field:name",
]
assert mod.would_break(g, "field:email") == [
    "action:save", "agent:crm", "query:all", "view:customers",
]
assert mod.affected_by(g, ["field:name", "shared:util"]) == [
    "action:save", "agent:crm", "query:all", "view:customers",
]

assert mod.dependencies(g, "missing") == []
assert mod.dependents(g, "missing") == []
assert mod.path_between(g, "missing", "field:name") is None
assert mod.would_break(g, "missing") == []
assert mod.affected_by(g, ["missing"]) == []

print("ok")
