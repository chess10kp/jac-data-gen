import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_NousResearch__hermes-agent__79543",
    Path(__file__).with_suffix(".py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

FenceError = mod.FenceError

SCOPES = ["portfolio", "ws", "project", "task"]
PARENTS = [("portfolio", "ws"), ("ws", "project"), ("project", "task")]
DEPS = [("ws", "project"), ("project", "task")]
REFS = [("task", "ws")]

g = mod.build_writer_store(SCOPES, PARENTS, DEPS, REFS)

assert mod.writer_children(g, "portfolio") == ["ws"]
assert mod.writer_children(g, "ghost") == []

assert mod.begin_attempt(g, "project", "a1") is True
assert mod.begin_attempt(g, "project", "a2") is False
assert mod.write_primitive(g, "project", "a1", "draft") is True
assert mod.write_primitive(g, "project", "a2", "stale") is False
assert mod.commit_attempt(g, "project", "a1") == ["draft"]

try:
    mod.commit_attempt(g, "project", "a1")
    raise AssertionError("expected FenceError")
except FenceError:
    pass

adv = mod.build_writer_store(
    ["r", "a", "b", "c"],
    [],
    [("r", "b"), ("r", "a"), ("a", "c"), ("b", "c")],
    [],
)
assert mod.reachable_scopes(adv, "r") == ["a", "b", "c"]
assert mod.reachable_scopes(adv, "ghost") == []

inv = mod.build_writer_store(SCOPES, PARENTS, DEPS, REFS)
assert mod.begin_attempt(inv, "task", "t1") is True
assert mod.write_primitive(inv, "task", "t1", "wip") is True
assert mod.invalidate_downstream(inv, "portfolio") == ["task"]
assert mod.begin_attempt(inv, "task", "t2") is True
assert mod.commit_attempt(inv, "task", "t2") == []

print("ok")
