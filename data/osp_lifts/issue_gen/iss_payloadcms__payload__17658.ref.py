"""Reference harness for iss_payloadcms__payload__17658."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_payloadcms__payload__17658.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
from iss_payloadcms__payload__17658 import (
    Doc,
    broken_breadcrumb_not_in_match,
    build_excluded_ids,
    collect_descendant_ids,
    connect_parent,
    filter_parent_candidates,
    make_doc,
    register_doc,
    would_create_cycle,
)

store: dict[str, Doc] = {}
cat2 = make_doc("391", "cat 2")
register_doc(store, cat2)
cat1 = make_doc("390", "cat 1")
register_doc(store, cat1)
connect_parent(cat2, cat1)
cat4 = make_doc("393", "cat 4")
register_doc(store, cat4)
connect_parent(cat1, cat4)
cat5 = make_doc("394", "cat 5")
register_doc(store, cat5)
connect_parent(cat4, cat5)
pool: list[str] = ["391", "390", "393", "394", "999"]
got = filter_parent_candidates("391", pool, store)
assert got == ["999"]
assert collect_descendant_ids("391", store) == ["390", "393", "394"]
assert build_excluded_ids("391", store) == ["390", "391", "393", "394"]

store2: dict[str, Doc] = {}
d = make_doc("D", "root")
register_doc(store2, d)
a = make_doc("A", "left")
register_doc(store2, a)
connect_parent(d, a)
b = make_doc("B", "right")
register_doc(store2, b)
connect_parent(d, b)
c = make_doc("C", "join")
register_doc(store2, c)
connect_parent(a, c)
e = make_doc("E", "deep")
register_doc(store2, e)
connect_parent(c, e)
connect_parent(b, c)
assert collect_descendant_ids("D", store2) == ["A", "B", "C", "E"]

store3: dict[str, Doc] = {}
lone = make_doc("1", "only")
register_doc(store3, lone)
assert collect_descendant_ids("missing", store3) == []
assert build_excluded_ids("missing", store3) == ["missing"]
assert filter_parent_candidates("missing", ["missing", "1", "9"], store3) == ["1", "9"]

self_only: list[str] = ["391"]
assert broken_breadcrumb_not_in_match("391", self_only) is False
mixed: list[str] = ["391", "390", "393", "394"]
assert broken_breadcrumb_not_in_match("391", mixed) is True

store4: dict[str, Doc] = {}
cat2b = make_doc("391", "cat 2")
register_doc(store4, cat2b)
cat1b = make_doc("390", "cat 1")
register_doc(store4, cat1b)
connect_parent(cat2b, cat1b)
cat5b = make_doc("394", "cat 5")
register_doc(store4, cat5b)
connect_parent(cat1b, cat5b)
assert would_create_cycle("391", "394", store4) is True
assert would_create_cycle("391", "999", store4) is False
print("iss_payloadcms__payload__17658 ref OK")
