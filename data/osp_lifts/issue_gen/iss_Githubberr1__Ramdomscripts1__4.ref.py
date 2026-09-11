"""Reference harness for iss_Githubberr1__Ramdomscripts1__4."""
import importlib.util
from pathlib import Path
_spec = importlib.util.spec_from_file_location("_mod", Path(__file__).with_name("iss_Githubberr1__Ramdomscripts1__4.py"))
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
org = _mod.make_org()
_mod.add_employee(org, "ceo", None)
_mod.add_employee(org, "mgr1", "ceo")
_mod.add_employee(org, "mgr2", "ceo")
_mod.add_employee(org, "emp1", "mgr1")
_mod.add_employee(org, "emp2", "mgr1")
assert sorted([x[0] for x in _mod.all_reports(org, "ceo")]) == ["emp1", "emp2", "mgr1", "mgr2"]
assert _mod.all_reports(org, "mgr1") == sorted(_mod.all_reports(org, "mgr1"))
reports = _mod.all_reports(org, "ceo")
# check levels
lvl = {e: l for e, l in reports}
assert lvl["mgr1"] == 1
assert lvl["emp1"] == 2
assert _mod.chain_to_root(org, "emp1") == ["emp1", "mgr1", "ceo"]
assert _mod.has_cycle(org) is False
# cycle
org2 = _mod.make_org()
_mod.add_employee(org2, "a", None)
_mod.add_employee(org2, "b", "a")
# manually create cycle via children manipulation
org2.children["b"].append("a")
org2.manager["a"] = "b"
assert _mod.has_cycle(org2) is True
# unknown manager returns empty
assert _mod.all_reports(org, "ghost") == []
# duplicate error
try:
    _mod.add_employee(org, "ceo", None)
    assert False
except ValueError:
    assert True
# top customers mock
orders = [
    {"customer_id": "c1", "total_amount": 100},
    {"customer_id": "c2", "total_amount": 200},
    {"customer_id": "c1", "total_amount": 50},
]
tops = _mod.top_customers_mock(orders)
assert tops[0][0] == "c2"
assert tops[0][1] == 200
print("iss_Githubberr1__Ramdomscripts1__4 ref OK")
