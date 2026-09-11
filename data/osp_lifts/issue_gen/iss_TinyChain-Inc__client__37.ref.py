import importlib.util
from pathlib import Path

p = Path(__file__).with_suffix(".py")
spec = importlib.util.spec_from_file_location("tc37", p)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

load_schema = mod.load_schema
annotated_fields = mod.annotated_fields
query_reach = mod.query_reach
mutate_bounded = mod.mutate_bounded

BASE = load_schema(
    [("user", "User"), ("admin", "Admin"), ("report", "Report")],
    [("admin", "user")],
    {
        "user": {"name": "writable", "id": "readonly"},
        "admin": {"role": "writable"},
        "report": {"title": "derived", "secret": "unsupported"},
    },
    [("u1", "user"), ("a1", "admin"), ("ro1", "report")],
    [("u1", "a1")],
)

assert annotated_fields(BASE, "user") == ["id", "name"]
assert annotated_fields(BASE, "admin") == ["id", "name", "role"]
assert annotated_fields(BASE, "report") == ["title"]
assert annotated_fields(BASE, "missing") == []

assert query_reach(BASE, "u1") == ["a1", "u1"]
assert mutate_bounded(BASE, "u1", 0) == ["u1"]
assert mutate_bounded(BASE, "u1", 1) == ["a1", "u1"]
assert mutate_bounded(BASE, "ro1", 0) == []
assert mutate_bounded(BASE, "missing", 2) == []

DIAMOND = load_schema(
    [("user", "User")],
    [],
    {"user": {"name": "writable"}},
    [("hub", "user"), ("left", "user"), ("right", "user"), ("cap", "user")],
    [("hub", "left"), ("hub", "right"), ("left", "cap"), ("right", "cap")],
)
assert query_reach(DIAMOND, "hub") == ["cap", "hub", "left", "right"]
assert mutate_bounded(DIAMOND, "hub", 1) == ["hub", "left", "right"]
assert mutate_bounded(DIAMOND, "hub", 2) == ["cap", "hub", "left", "right"]

CYCLE = load_schema(
    [("user", "User")],
    [],
    {"user": {"name": "writable"}},
    [("a", "user"), ("b", "user"), ("c", "user")],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert query_reach(CYCLE, "a") == ["a", "b", "c"]
assert mutate_bounded(CYCLE, "a", 2) == ["a", "b", "c"]
