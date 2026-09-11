import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_spring-projects__spring-security__19513",
    Path(__file__).with_name("iss_spring-projects__spring-security__19513.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_acls(["a", "b", "c", "d"], [("b", "a"), ("c", "b"), ("d", "c")])
assert mod.ancestor_ids(store, "d") == ["a", "b", "c"]
assert mod.lookup_ancestors_safe(store, "d") == ["a", "b", "c"]
assert mod.would_create_cycle(store, "a", "d") is True
try:
    mod.set_parent(store, "a", "d")
    raise AssertionError("expected cycle rejection")
except ValueError:
    pass

store2 = mod.load_acls(["x", "y"], [("x", "y"), ("y", "x")])
try:
    mod.lookup_ancestors_safe(store2, "x")
    raise AssertionError("expected stored cycle error")
except ValueError:
    pass
print("ok")
