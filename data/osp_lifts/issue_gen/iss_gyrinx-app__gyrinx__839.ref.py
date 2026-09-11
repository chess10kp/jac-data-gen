"""Reference harness for iss_gyrinx-app__gyrinx__839."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_gyrinx-app__gyrinx__839.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_gyrinx-app__gyrinx__839.py")
_spec = importlib.util.spec_from_file_location("issue839", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_gear_store()
assert s0 == {"categories": {}, "fighters": {}, "deps": {}, "nodes": {}, "roots": []}
s0 = m.register_category("melee", "Melee", s0)
assert s0["categories"]["melee"] == "Melee"
assert s0["roots"] == ["melee"]

s = m.fresh_gear_store()
m.register_category("melee", "Melee", s)
m.register_category("ranged", "Ranged", s)
m.register_category("special", "Special", s)
m.register_category("heavy", "Heavy", s)
m.add_cat_child("melee", "special", s)
m.add_cat_child("melee", "ranged", s)
m.add_cat_child("ranged", "heavy", s)
m.add_cat_child("special", "heavy", s)
m.register_fighter_category("infantry", s)
m.add_fighter_restriction("heavy", "infantry", s)
pref = m.prefetch_restricted_ids("infantry", s)
assert pref == ["heavy"]
got = m.restricted_category_ids("infantry", ["melee", "ranged", "special", "heavy"], s)
assert got == ["heavy"]

s1 = m.fresh_gear_store()
for cid, name in (("melee", "Melee"), ("ranged", "Ranged"), ("special", "Special"), ("heavy", "Heavy")):
    m.register_category(cid, name, s1)
m.add_cat_child("melee", "special", s1)
m.add_cat_child("special", "heavy", s1)
m.add_cat_child("melee", "ranged", s1)
m.add_cat_child("ranged", "heavy", s1)
m.register_fighter_category("infantry", s1)
m.add_fighter_restriction("heavy", "infantry", s1)
s2 = m.fresh_gear_store()
for cid, name in (("melee", "Melee"), ("ranged", "Ranged"), ("special", "Special"), ("heavy", "Heavy")):
    m.register_category(cid, name, s2)
m.add_cat_child("melee", "ranged", s2)
m.add_cat_child("ranged", "heavy", s2)
m.add_cat_child("melee", "special", s2)
m.add_cat_child("special", "heavy", s2)
m.register_fighter_category("infantry", s2)
m.add_fighter_restriction("heavy", "infantry", s2)
assert m.prefetch_restricted_ids("infantry", s1) == m.prefetch_restricted_ids("infantry", s2)

s = m.fresh_gear_store()
m.register_category("melee", "Melee", s)
m.register_fighter_category("infantry", s)
try:
    m.add_cat_child("melee", "missing", s)
    raise AssertionError("expected KeyError for unknown child category")
except KeyError:
    pass
try:
    m.restricted_category_ids("infantry", ["missing"], s)
    raise AssertionError("expected KeyError for unknown filter category")
except KeyError:
    pass

s = m.fresh_gear_store()
m.register_category("melee", "Melee", s)
m.register_category("ranged", "Ranged", s)
m.register_category("special", "Special", s)
m.register_fighter_category("infantry", s)
m.register_fighter_category("vehicle", s)
m.add_fighter_restriction("melee", "infantry", s)
m.add_fighter_restriction("special", "infantry", s)
m.add_fighter_restriction("ranged", "vehicle", s)
blocked = m.restricted_category_ids("infantry", ["melee", "ranged", "special"], s)
assert blocked == ["melee", "special"]
rep = m.restriction_report("infantry", ["melee", "ranged", "special"], s)
assert rep["allowed"] == ["ranged"]
assert rep["query_count"] == 1
assert rep["prefetch_count"] == 2
assert rep["blocked"] == ["melee", "special"]

s = m.fresh_gear_store()
m.register_category("melee", "Melee", s)
m.register_category("ranged", "Ranged", s)
m.register_fighter_category("infantry", s)
m.add_fighter_restriction("melee", "vehicle", s)
got = m.restricted_category_ids("infantry", ["melee", "ranged"], s)
assert got == []
rep = m.restriction_report("infantry", ["melee", "ranged"], s)
assert rep["blocked"] == []
assert rep["allowed"] == ["melee", "ranged"]
assert m.register_fighter_category("vehicle", s) is s
print("iss_gyrinx-app__gyrinx__839 ref OK")
