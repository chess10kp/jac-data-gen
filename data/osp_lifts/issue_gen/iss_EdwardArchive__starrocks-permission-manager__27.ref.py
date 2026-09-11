"""Reference harness: exercises every public function."""
import importlib.util
import pathlib

_mod_path = pathlib.Path(__file__).parent / "iss_EdwardArchive__starrocks-permission-manager__27.py"
_spec = importlib.util.spec_from_file_location("sr_lineage_mod", _mod_path)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

build_catalog = _mod.build_catalog
direct_sources = _mod.direct_sources
upstream_lineage = _mod.upstream_lineage
downstream_impact = _mod.downstream_impact
has_circular_mv = _mod.has_circular_mv
MAX_LINEAGE_DEPTH = _mod.MAX_LINEAGE_DEPTH

OBJECTS = [
    ("analytics.customers", "TABLE"),
    ("analytics.orders", "TABLE"),
    ("analytics.products", "TABLE"),
    ("analytics.revenue_summary", "MV"),
    ("analytics.quarterly_report", "VIEW"),
]
REFS = [
    ("analytics.revenue_summary", "analytics.customers"),
    ("analytics.revenue_summary", "analytics.orders"),
    ("analytics.revenue_summary", "analytics.products"),
    ("analytics.quarterly_report", "analytics.revenue_summary"),
]
CAT = build_catalog(OBJECTS, REFS)

assert direct_sources(CAT, "analytics.quarterly_report") == ["analytics.revenue_summary"]
assert direct_sources(CAT, "analytics.revenue_summary") == [
    "analytics.customers", "analytics.orders", "analytics.products",
]
assert direct_sources(CAT, "analytics.customers") == []
assert direct_sources(CAT, "ghost.table") == []

assert upstream_lineage(CAT, "analytics.quarterly_report", max_depth=1) == ["analytics.revenue_summary"]
assert upstream_lineage(CAT, "analytics.quarterly_report", max_depth=2) == [
    "analytics.customers", "analytics.orders", "analytics.products", "analytics.revenue_summary",
]
assert upstream_lineage(CAT, "analytics.quarterly_report") == [
    "analytics.customers", "analytics.orders", "analytics.products", "analytics.revenue_summary",
]
assert upstream_lineage(CAT, "analytics.revenue_summary", max_depth=0) == []

assert downstream_impact(CAT, "analytics.customers") == [
    "analytics.quarterly_report", "analytics.revenue_summary",
]
assert downstream_impact(CAT, "analytics.quarterly_report") == []
assert downstream_impact(CAT, "ghost.table") == []

assert has_circular_mv(CAT) is False

CYCLE_CAT = build_catalog(
    [("db.mv_a", "MV"), ("db.mv_b", "MV"), ("db.base", "TABLE")],
    [("db.mv_a", "db.mv_b"), ("db.mv_b", "db.mv_a"), ("db.mv_b", "db.base")],
)
assert has_circular_mv(CYCLE_CAT) is True

VIEW_CYCLE = build_catalog(
    [("db.v_a", "VIEW"), ("db.v_b", "VIEW")],
    [("db.v_a", "db.v_b"), ("db.v_b", "db.v_a")],
)
assert has_circular_mv(VIEW_CYCLE) is False

assert MAX_LINEAGE_DEPTH == 5

print("starrocks-permission-manager 27 ref OK")
