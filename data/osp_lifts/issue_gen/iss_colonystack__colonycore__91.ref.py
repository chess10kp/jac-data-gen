"""Reference harness for iss_colonystack__colonycore__91."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_colonystack__colonycore__91.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_colonystack__colonycore__91.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

get_ancestors = _mod.get_ancestors
get_descendants = _mod.get_descendants
traverse_rel_chain = _mod.traverse_rel_chain
list_rel_targets = _mod.list_rel_targets
traversal_probe = _mod.traversal_probe

assert get_ancestors("asn_1") == ["col_a", "sub_1"]
assert get_ancestors("col_a") == []
assert get_ancestors("stp_1") == ["prt_p"]
assert get_ancestors("ver_2") == ["prt_p", "stp_2"]
assert get_ancestors("missing") == []
assert get_ancestors("ver_1", max_depth=1) == ["stp_1"]
assert get_ancestors("asn_1", max_depth=0) == []

assert get_descendants("col_a") == ["asn_1", "asn_2", "asn_3", "sub_1", "sub_2"]
assert get_descendants("sub_1") == ["asn_1", "asn_2"]
assert get_descendants("asn_1") == []
assert get_descendants("prt_p") == ["stp_1", "stp_2", "stp_3", "ver_1", "ver_2"]
assert get_descendants("stp_1", max_depth=1) == ["ver_1"]
assert get_descendants("col_a", max_depth=0) == []
assert get_descendants("prt_p", max_depth=0) == []
assert get_descendants("missing") == []

assert traverse_rel_chain("col_a", ("colony_subject",)) == ["sub_1", "sub_2"]
assert traverse_rel_chain("col_a", ("colony_subject", "subject_assignment")) == [
    "asn_1", "asn_2", "asn_3", "sub_1", "sub_2",
]
assert traverse_rel_chain("prt_p", ("protocol_step",)) == ["stp_1", "stp_2", "stp_3"]
assert traverse_rel_chain("col_a", ()) == []
assert traverse_rel_chain("prt_p", ()) == []
assert traverse_rel_chain("col_a", ("colony_subject", "no_such_rel")) == ["sub_1", "sub_2"]
assert traverse_rel_chain("prt_p", ("protocol_step", "bogus_kind")) == ["stp_1", "stp_2", "stp_3"]
assert traverse_rel_chain("missing", ("colony_subject",)) == []

assert list_rel_targets("prt_p", "protocol_step") == ["stp_1", "stp_2", "stp_3"]
assert list_rel_targets("sub_1", "subject_assignment") == ["asn_1", "asn_2"]
assert list_rel_targets("col_a", "protocol_step") == []
assert list_rel_targets("col_a", "no_such_rel") == []
assert list_rel_targets("missing", "protocol_step") == []

assert traversal_probe("asn_1") == {"visited": 3, "edges": 2, "depth": 2}
assert traversal_probe("col_a") == {"visited": 6, "edges": 5, "depth": 0}
assert traversal_probe("prt_p") == {"visited": 6, "edges": 5, "depth": 0}
assert traversal_probe("missing") == {"visited": 0, "edges": 0, "depth": 0}

assert get_ancestors("ghost") == []
assert get_descendants("ghost") == []
assert list_rel_targets("ghost", "colony_subject") == []
assert list_rel_targets("ghost", "protocol_step") == []
assert traverse_rel_chain("ghost", ("colony_subject",)) == []
assert traversal_probe("ghost") == {"visited": 0, "edges": 0, "depth": 0}
print("iss_colonystack__colonycore__91 ref OK")
