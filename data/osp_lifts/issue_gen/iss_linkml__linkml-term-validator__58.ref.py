"""Reference harness for iss_linkml__linkml-term-validator__58."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_linkml__linkml-term-validator__58.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
OntologyStore = _mod.OntologyStore
descendants = _mod.descendants
ancestors = _mod.ancestors

s = OntologyStore()
s.add_term("GO:ROOT")
s.add_term("GO:A")
s.add_term("GO:B")
s.add_term("GO:X")
s.link_is_a("GO:B", "GO:ROOT")
s.link_is_a("GO:A", "GO:ROOT")
s.link_is_a("GO:X", "GO:B")
s.link_is_a("GO:X", "GO:A")
assert descendants(s, "GO:ROOT") == sorted(["GO:A", "GO:B", "GO:ROOT", "GO:X"])

s2 = OntologyStore()
s2.add_term("GO:ROOT")
assert descendants(s2, "MISSING:999") == []
assert ancestors(s2, "MISSING:999") == []

s3 = OntologyStore()
s3.add_term("GO:0005575")
s3.add_term("GO:0005623")
s3.add_term("MRO:0000001")
s3.link_is_a("GO:0005623", "GO:0005575")
s3.link_is_a("MRO:0000001", "GO:0005575")
all_ids = descendants(s3, "GO:0005575")
go_ids = descendants(s3, "GO:0005575", prefix_filter="GO:")
assert all_ids == sorted(["GO:0005575", "GO:0005623", "MRO:0000001"])
assert go_ids == sorted(["GO:0005575", "GO:0005623"])

s4 = OntologyStore()
s4.add_term("GO:CC")
s4.add_term("GO:PART")
s4.link_part_of("GO:PART", "GO:CC")
assert descendants(s4, "GO:CC", include_part_of=False) == ["GO:CC"]
assert descendants(s4, "GO:CC", include_part_of=True) == sorted(["GO:CC", "GO:PART"])

s5 = OntologyStore()
s5.add_term("GO:1")
s5.add_term("GO:2")
s5.add_term("GO:3")
s5.link_is_a("GO:3", "GO:2")
s5.link_is_a("GO:2", "GO:1")
assert ancestors(s5, "GO:3") == sorted(["GO:1", "GO:2", "GO:3"])

t = s.add_term("GO:PROBE")
assert t.term_id == "GO:PROBE"
assert "GO:PROBE" in s.terms_by_id
s.link_is_a("GO:MISSING", "GO:ROOT")
s.link_is_a("GO:A", "GO:MISSING")
s.link_part_of("GO:MISSING", "GO:CC")
s.link_part_of("GO:PART", "GO:MISSING")
print("iss_linkml__linkml-term-validator__58 ref OK")
