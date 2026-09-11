"""Reference harness: exercises every public function."""
import importlib.util
from pathlib import Path

_MOD = Path(__file__).with_name("iss_Baymine__OLAP-radar__178.py")
_spec = importlib.util.spec_from_file_location("olap_digest_mod", _MOD)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

build_catalog = _mod.build_catalog
direct_upstream = _mod.direct_upstream
upstream_closure = _mod.upstream_closure
lineage_digest = _mod.lineage_digest
MAX_LINEAGE_DEPTH = _mod.MAX_LINEAGE_DEPTH

COMPONENTS = ["doris", "gluten", "velox", "arrow", "iceberg"]
REFS = [
    ("doris", "gluten"),
    ("doris", "iceberg"),
    ("gluten", "velox"),
    ("velox", "arrow"),
]
CAT = build_catalog(COMPONENTS, REFS)

assert direct_upstream(CAT, "doris") == ["gluten", "iceberg"]
assert direct_upstream(CAT, "arrow") == []
assert direct_upstream(CAT, "ghost") == []

assert upstream_closure(CAT, "doris", max_depth=1) == ["gluten", "iceberg"]
assert upstream_closure(CAT, "doris", max_depth=2) == ["gluten", "iceberg", "velox"]
assert upstream_closure(CAT, "doris") == ["arrow", "gluten", "iceberg", "velox"]
assert upstream_closure(CAT, "doris", max_depth=0) == []
assert upstream_closure(CAT, "ghost") == []

assert lineage_digest(CAT, "doris", max_depth=1) == [
    "doris", "gluten", "iceberg",
]
assert lineage_digest(CAT, "doris") == [
    "arrow", "doris", "gluten", "iceberg", "velox",
]
assert lineage_digest(CAT, "ghost") == []

# Adversarial edge order: shared mid reached before deeper branches settle.
DIAMOND = build_catalog(
    ["top", "a", "b", "mid", "leaf"],
    [
        ("top", "mid"),
        ("mid", "leaf"),
        ("b", "mid"),
        ("a", "mid"),
    ],
)
assert upstream_closure(DIAMOND, "top", max_depth=2) == ["a", "b", "leaf", "mid"]
assert lineage_digest(DIAMOND, "top", max_depth=2) == ["a", "b", "leaf", "mid", "top"]

assert MAX_LINEAGE_DEPTH == 5
print("OLAP-radar 178 ref OK")
