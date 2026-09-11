"""Reference harness for iss_RicoSuter__Namotion.Interceptor__410."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_RicoSuter__Namotion__Interceptor__410.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
create_registry = _mod.create_registry
add_subject = _mod.add_subject
bind_property = _mod.bind_property
register_service = _mod.register_service
detach_subject = _mod.detach_subject
list_fallback_edges = _mod.list_fallback_edges
resolve_service = _mod.resolve_service
delegation_cycle_nodes = _mod.delegation_cycle_nodes
reachable_via_fallback = _mod.reachable_via_fallback
# partial detach strands mutual fallback edges (issue reproduction)
reg = create_registry()
add_subject(reg, "root")
add_subject(reg, "A", "root")
add_subject(reg, "B", "root")
bind_property(reg, "A", "peer", "B")
bind_property(reg, "B", "peer", "A")
assert list_fallback_edges(reg) == [("A", "B"), ("B", "A")]
assert delegation_cycle_nodes(reg) == ["A", "B"]
assert reachable_via_fallback(reg, "A") == ["B"]
try:
    resolve_service(reg, "A", "missing")
    assert False, "expected DelegationCycleError"
except _mod.DelegationCycleError:
    pass
detach_subject(reg, "A", property_removed=False)
assert list_fallback_edges(reg) == [("A", "B"), ("B", "A")]
assert delegation_cycle_nodes(reg) == ["A", "B"]

# full detach strips inherited fallback from detached subject only
reg2 = create_registry()
add_subject(reg2, "root")
add_subject(reg2, "A", "root")
add_subject(reg2, "B", "root")
bind_property(reg2, "A", "peer", "B")
bind_property(reg2, "B", "peer", "A")
detach_subject(reg2, "A", property_removed=True)
assert list_fallback_edges(reg2) == [("B", "A")]
assert delegation_cycle_nodes(reg2) == []

# cycle with a service on one side resolves successfully
reg3 = create_registry()
add_subject(reg3, "A")
add_subject(reg3, "B")
bind_property(reg3, "A", "peer", "B")
bind_property(reg3, "B", "peer", "A")
register_service(reg3, "A", "svc")
assert delegation_cycle_nodes(reg3) == []
assert resolve_service(reg3, "B", "svc") == "A"

# stale resolution through a partially detached context
reg4 = create_registry()
add_subject(reg4, "A")
add_subject(reg4, "C")
bind_property(reg4, "A", "ctx", "C")
register_service(reg4, "C", "orphan_svc")
detach_subject(reg4, "C", property_removed=False)
assert list_fallback_edges(reg4) == [("A", "C")]
assert resolve_service(reg4, "A", "orphan_svc") == "C"

# adversarial-order diamond reachability and negative resolve
reg5 = create_registry()
add_subject(reg5, "A")
add_subject(reg5, "B")
add_subject(reg5, "C")
add_subject(reg5, "D")
bind_property(reg5, "C", "d", "D")
bind_property(reg5, "B", "d", "D")
bind_property(reg5, "A", "c", "C")
bind_property(reg5, "A", "b", "B")
assert reachable_via_fallback(reg5, "A") == ["B", "C", "D"]
assert resolve_service(reg5, "A", "nope") is None
print("iss_RicoSuter__Namotion.Interceptor__410 ref OK")
