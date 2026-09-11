import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

REL = [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")]
POLICY = [("a", "b"), ("b", "c")]
HIER = [("dog", "animal"), ("dog", "pet"), ("animal", "thing")]
CYCLE = [("a", "b"), ("b", "c"), ("c", "a")]
FACTS = [("alice", "knows", "bob"), ("bob", "knows", "carol")]
RULES = [
    (
        [("?x", "knows", "?y"), ("?y", "knows", "?z")],
        ("?x", "knows2", "?z"),
    )
]

assert mod.guided_traversal("a", REL, {"a", "b", "c", "d"}) == ["a", "b", "c", "d"]
assert mod.guided_traversal("a", POLICY, {"a", "b"}) == ["a", "b"]
assert mod.hierarchy_closure("dog", HIER) == ["dog", "animal", "pet", "thing"]
try:
    mod.hierarchy_closure("a", CYCLE)
    raise AssertionError("expected ValueError")
except ValueError:
    pass
assert mod.apply_rules(FACTS, RULES) == [("alice", "knows2", "carol")]
print("ok")
