"""Reference harness for iss_EffortlessMetrics__perl-lsp-swarm__7648."""
import importlib.util
from pathlib import Path
_spec = importlib.util.spec_from_file_location("_mod", Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__7648.py"))
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
reg = _mod.make_registry()
_mod.register_moose_attribute(reg, "MyClass", "name", "ro", {})
_mod.register_moose_attribute(reg, "MyClass", "bare_attr", "bare", {})
_mod.register_moose_attribute(reg, "MyClass", "no_acc", None, {})
assert _mod.provided_members(reg, "MyClass") == ["name"]
# lazy_build hook
reg2 = _mod.make_registry()
_mod.register_moose_attribute(reg2, "Foo", "x", "ro", {"lazy_build": True})
assert _mod.referenced_hooks(reg2, "Foo::x") == ["_build_x"]
# constraint
reg3 = _mod.make_registry()
_mod.register_moose_attribute(reg3, "Klass", "age", "rw", {"isa": "Int"})
assert _mod.constraint_for(reg3, "Klass::age") == "Int"
_mod.register_moose_attribute(reg3, "Klass", "dyn", "rw", {"isa": 123})
assert _mod.constraint_for(reg3, "Klass::dyn") == "dynamic"
# inheritance
reg4 = _mod.make_registry()
_mod.register_moose_attribute(reg4, "Base", "b", "ro", {})
_mod.register_moose_attribute(reg4, "Child", "c", "rw", {})
_mod.add_extends(reg4, "Child", "Base")
assert _mod.provided_members(reg4, "Child") == ["b", "c"]
assert _mod.ancestor_chain(reg4, "Child") == ["Child", "Base"]
# invalid is_mode
try:
    _mod.register_moose_attribute(reg4, "X", "y", "rwp", {})
    assert False
except ValueError:
    assert True
print("iss_EffortlessMetrics__perl-lsp-swarm__7648 ref OK")
