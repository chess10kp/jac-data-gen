"""Reference harness: exercises every public function of iss_k-sandhu__dq-sentinel__242."""
import importlib.util
import pathlib

_mod_path = pathlib.Path(__file__).parent / "iss_k-sandhu__dq-sentinel__242.py"
_spec = importlib.util.spec_from_file_location("dqsentinel_mod", _mod_path)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
build_catalog = _mod.build_catalog
impacted_assets = _mod.impacted_assets
normalize_table_ref = _mod.normalize_table_ref
unmatched_refs = _mod.unmatched_refs

DATASETS = [
    "wh.finance.transactions",
    "wh.finance.daily_balances",
    "wh.marts.balance_mart",
    "wh.marts.kpi_dashboard_src",
]
DEPS = [
    ("wh.marts.balance_mart", "wh.finance.transactions"),
    ("wh.marts.balance_mart", "wh.finance.daily_balances"),
    ("wh.marts.kpi_dashboard_src", "wh.marts.balance_mart"),
]
ASSETS = [
    ("dash-001", "dashboard", "CFO Overview", [
        ("WH", "Finance", "Transactions"),
        ("WH", "marts", "KPI_DASHBOARD_SRC"),
    ]),
    ("wb-77", "workbook", "Treasury WB", [
        ("wh", "MARTS", "Balance_Mart"),
        ("wh", "staging", "unknown_table"),   # never silently dropped
    ]),
    ("dash-002", "dashboard", "Ops Board", [
        ("wh", "other_db", "unrelated"),      # all-unmatched asset
    ]),
]

cat = build_catalog(DATASETS, DEPS, ASSETS)

assert normalize_table_ref(" WH ", "Finance", "TX ") == "wh.finance.tx"

# Impact flows upstream through the mart chain to the dashboards.
assert impacted_assets(cat, "wh.finance.transactions") == ["dash-001", "wb-77"]
assert impacted_assets(cat, "wh.marts.balance_mart") == ["dash-001", "wb-77"]
# dash-001 reads the KPI mart too, so daily_balances reaches it as well.
assert impacted_assets(cat, "wh.finance.daily_balances") == ["dash-001", "wb-77"]
assert impacted_assets(cat, "wh.marts.kpi_dashboard_src") == ["dash-001"]

# Unmatched refs are reported, never dropped.
assert unmatched_refs(cat) == [
    ("dash-002", "wh.other_db.unrelated"),
    ("wb-77", "wh.staging.unknown_table"),
]

# Unknown dataset impacts nothing.
assert impacted_assets(cat, "wh.ghost") == []

print("dq-sentinel 242 ref OK")
