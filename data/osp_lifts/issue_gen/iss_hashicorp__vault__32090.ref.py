"""Reference harness for iss_hashicorp__vault__32090."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_hashicorp__vault__32090.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_hashicorp__vault__32090.py")
_spec = importlib.util.spec_from_file_location("issue32090", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_vault_store()
assert s0 == {
    "mounts": {},
    "secrets": {},
    "deps": {},
    "nodes": {},
    "mount_nodes": {},
    "roots": {},
    "counters": {},
}
s0 = m.register_mount("kv1", s0)
assert s0["mounts"]["kv1"] is True
assert s0["counters"]["kv1"] == 0
assert s0["roots"]["kv1"] == []

s = m.fresh_vault_store()
m.register_mount("kv1", s)
m.register_secret("meta_a", s)
m.register_secret("meta_b", s)
m.register_secret("meta_c", s)
m.register_secret("meta_d", s)
m.add_mount_root("kv1", "meta_a", s)
m.add_secret_child("meta_a", "meta_b", s)
m.add_secret_child("meta_a", "meta_c", s)
m.add_secret_child("meta_b", "meta_d", s)
m.add_secret_child("meta_c", "meta_d", s)
scan = m.recursive_list_count("kv1", s)
assert scan["secret_count"] == 4
assert scan["list_calls"] == 4
assert sum(1 for sid in scan["secrets"] if sid == "meta_d") == 1

s1 = m.fresh_vault_store()
m.register_mount("kv1", s1)
for sid in ("meta_a", "meta_b", "meta_c", "meta_d"):
    m.register_secret(sid, s1)
m.add_mount_root("kv1", "meta_a", s1)
m.add_secret_child("meta_a", "meta_c", s1)
m.add_secret_child("meta_c", "meta_d", s1)
m.add_secret_child("meta_a", "meta_b", s1)
m.add_secret_child("meta_b", "meta_d", s1)
s2 = m.fresh_vault_store()
m.register_mount("kv1", s2)
for sid in ("meta_a", "meta_b", "meta_c", "meta_d"):
    m.register_secret(sid, s2)
m.add_mount_root("kv1", "meta_a", s2)
m.add_secret_child("meta_a", "meta_b", s2)
m.add_secret_child("meta_b", "meta_d", s2)
m.add_secret_child("meta_a", "meta_c", s2)
m.add_secret_child("meta_c", "meta_d", s2)
assert m.recursive_list_count("kv1", s1)["secrets"] == m.recursive_list_count("kv1", s2)["secrets"]

s = m.fresh_vault_store()
m.register_mount("kv1", s)
m.register_secret("meta_a", s)
try:
    m.recursive_list_count("missing", s)
    raise AssertionError("expected KeyError for unknown mount")
except KeyError:
    pass
try:
    m.add_secret_child("meta_a", "missing", s)
    raise AssertionError("expected KeyError for unknown secret")
except KeyError:
    pass

s = m.fresh_vault_store()
m.register_mount("kv1", s)
for sid in ("meta_a", "meta_b", "meta_c", "meta_d"):
    m.register_secret(sid, s)
m.add_mount_root("kv1", "meta_a", s)
m.add_secret_child("meta_a", "meta_b", s)
m.add_secret_child("meta_b", "meta_c", s)
m.add_secret_child("meta_c", "meta_d", s)
scan = m.recursive_list_count("kv1", s, list_cap=2)
assert scan["truncated"] is True
assert scan["list_calls"] == 2
assert scan["secret_count"] == 2

s = m.fresh_vault_store()
m.register_mount("kv1", s)
m.register_secret("meta_a", s)
m.add_mount_root("kv1", "meta_a", s)
m.set_mount_counter("kv1", 42, s)
list_rep = m.billing_report("kv1", s, use_endpoint=False)
end_rep = m.billing_report("kv1", s, use_endpoint=True)
assert list_rep["list_calls"] == 1
assert list_rep["mode"] == m.MODE_LIST
assert end_rep["list_calls"] == 0
assert end_rep["secret_count"] == 42
assert end_rep["mode"] == m.MODE_ENDPOINT
assert end_rep["truncated"] is False
try:
    m.set_mount_counter("missing", 1, s)
    raise AssertionError("expected KeyError for unknown mount counter")
except KeyError:
    pass
print("iss_hashicorp__vault__32090 ref OK")
