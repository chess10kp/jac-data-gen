"""Reference harness for iss_EffortlessMetrics__perl-lsp-swarm__4908."""
import importlib.util
from pathlib import Path
_spec = importlib.util.spec_from_file_location("_mod", Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__4908.py"))
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
reg = _mod.make_registry()
_mod.register_attribute(reg, "MyClass", "name", "ro", {})
_mod.register_attribute(reg, "MyClass", "age", "rw", {"builder": "_build_age", "trigger": "_trig"})
assert sorted(_mod.provided_members(reg, "MyClass")) == ["age", "name"]
assert _mod.referenced_hooks(reg, "MyClass::age") == ["_build_age", "_trig"]
# rwp provides writer
reg2 = _mod.make_registry()
_mod.register_attribute(reg2, "Foo", "x", "rwp", {})
assert "_set_x" in _mod.provided_members(reg2, "Foo")
# invalid is mode
try:
    _mod.register_attribute(reg2, "Foo", "bad", "bare", {})
    assert False, "should reject bare for Moo"
except ValueError:
    assert True
# inheritance BFS
reg3 = _mod.make_registry()
_mod.register_attribute(reg3, "Base", "base_attr", "ro", {})
_mod.register_attribute(reg3, "Child", "child_attr", "rw", {})
_mod.add_extends(reg3, "Child", "Base")
assert _mod.provided_members(reg3, "Child") == ["base_attr", "child_attr"]
assert _mod.provided_members(reg3, "Base") == ["base_attr"]
assert _mod.ancestor_chain(reg3, "Child") == ["Child", "Base"]
# diamond order independent
reg4 = _mod.make_registry()
_mod.register_attribute(reg4, "A", "a", "ro", {})
_mod.add_extends(reg4, "B", "A")
_mod.add_extends(reg4, "C", "A")
assert sorted(_mod.provided_members(reg4, "B")) == ["a"]
# duplicate attribute error
try:
    _mod.register_attribute(reg4, "A", "a", "ro", {})
    assert False
except ValueError:
    assert True
print("iss_EffortlessMetrics__perl-lsp-swarm__4908 ref OK")
