"""Reference harness for iss_jessealama__thales__144."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_jessealama__thales__144.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
from iss_jessealama__thales__144 import (
    KIND_DEF,
    KIND_STRUCT,
    add_reference,
    classify_forward_reference,
    direct_references,
    fresh_emission_store,
    hybrid_emit_plan,
    mutual_recursion_groups,
    prerequisite_order,
    reference_closure,
    register_declaration,
)

assert fresh_emission_store().decls == {}

s = fresh_emission_store()
register_declaration("g", KIND_DEF, 1, s)
register_declaration("f", KIND_DEF, 0, s)
add_reference("f", "g", s)
assert prerequisite_order(s) == ["g", "f"]
assert classify_forward_reference("f", "g", s) == "accepted_linear"
assert direct_references("f", s) == ["g"]
assert sorted(reference_closure("f", s)) == ["f", "g"]

s = fresh_emission_store()
register_declaration("hub", KIND_DEF, 0, s)
register_declaration("left", KIND_DEF, 1, s)
register_declaration("right", KIND_DEF, 2, s)
register_declaration("sink", KIND_DEF, 3, s)
add_reference("left", "sink", s)
add_reference("right", "sink", s)
add_reference("hub", "right", s)
add_reference("hub", "left", s)
assert sorted(reference_closure("hub", s)) == ["hub", "left", "right", "sink"]

s = fresh_emission_store()
register_declaration("f", KIND_DEF, 0, s)
register_declaration("g", KIND_DEF, 1, s)
add_reference("f", "g", s)
add_reference("g", "f", s)
assert mutual_recursion_groups(s) == [["f", "g"]]
assert classify_forward_reference("f", "g", s) == "accepted_mutual"
plan = hybrid_emit_plan(s)
assert plan["linear_defs"] == []
assert plan["mutual_groups"] == [["f", "g"]]
assert plan["structures"] == []

s = fresh_emission_store()
register_declaration("a", KIND_DEF, 0, s)
assert classify_forward_reference("ghost", "a", s) == "reject_unknown"
caught = False
try:
    direct_references("ghost", s)
except KeyError:
    caught = True
assert caught

s = fresh_emission_store()
register_declaration("scale", KIND_DEF, 0, s)
register_declaration("Point", KIND_STRUCT, 1, s)
add_reference("scale", "Point", s)
plan = hybrid_emit_plan(s)
assert plan["structures"] == ["Point"]
assert plan["linear_defs"] == ["scale"]
assert classify_forward_reference("scale", "Point", s) == "accepted_linear"

s = fresh_emission_store()
register_declaration("later", KIND_DEF, 2, s)
register_declaration("earlier", KIND_DEF, 0, s)
add_reference("later", "earlier", s)
assert classify_forward_reference("later", "earlier", s) == "source_ok"
assert classify_forward_reference("earlier", "later", s) == "no_reference"

s = fresh_emission_store()
register_declaration("f", KIND_DEF, 0, s)
register_declaration("g", KIND_DEF, 1, s)
register_declaration("h", KIND_DEF, 5, s)
register_declaration("i", KIND_DEF, 6, s)
add_reference("f", "g", s)
add_reference("g", "f", s)
add_reference("h", "i", s)
add_reference("i", "h", s)
add_reference("f", "h", s)
assert classify_forward_reference("f", "h", s) == "reject_incompatible"

s = fresh_emission_store()
register_declaration("x", KIND_DEF, 0, s)
dup = False
try:
    register_declaration("x", KIND_DEF, 1, s)
except ValueError:
    dup = True
assert dup

s = fresh_emission_store()
register_declaration("only", KIND_DEF, 0, s)
ref_err = False
try:
    add_reference("only", "missing", s)
except KeyError:
    ref_err = True
assert ref_err

s2 = register_declaration("solo", KIND_DEF, 0, None)
assert "solo" in s2.decls
print("iss_jessealama__thales__144 ref OK")
