"""Reference harness for iss_Sirivennela-ANW__Epics_userstories__46."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Sirivennela-ANW__Epics_userstories__46.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
cat = _mod.load_lineage_catalog(
    [
        ("raw_orders", "bronze", 1000),
        ("raw_events", "bronze", 500),
        ("clean_orders", "silver", 800),
        ("clean_events", "silver", 400),
        ("joined", "silver", 600),
        ("metrics", "gold", 200),
        ("report", "gold", 100),
    ],
    [
        ("raw_orders", "clean_orders", "dedupe", 0.95, 120),
        ("raw_events", "clean_events", "filter", 0.90, 80),
        ("clean_orders", "joined", "join", 0.88, 200),
        ("clean_events", "joined", "join", 0.88, 200),
        ("joined", "metrics", "aggregate", 0.92, 150),
        ("metrics", "report", "publish", 0.99, 50),
    ],
)

assert _mod.origin_lineage(cat, "report") == [
    "clean_events",
    "clean_orders",
    "joined",
    "metrics",
    "raw_events",
    "raw_orders",
]
assert _mod.origin_lineage(cat, "raw_orders") == []
assert _mod.origin_lineage(cat, "missing") == []

assert _mod.impact_lineage(cat, "raw_orders") == [
    "clean_orders",
    "joined",
    "metrics",
    "report",
]
assert _mod.impact_lineage(cat, "report") == []
assert _mod.impact_lineage(cat, "ghost") == []

assert _mod.lineage_paths(cat, "report", "raw_orders") == [
    ["report", "metrics", "joined", "clean_orders", "raw_orders"],
]
assert _mod.lineage_paths(cat, "report", "raw_events") == [
    ["report", "metrics", "joined", "clean_events", "raw_events"],
]
assert _mod.lineage_paths(cat, "joined", "raw_orders") == [
    ["joined", "clean_orders", "raw_orders"],
]
assert _mod.lineage_paths(cat, "report", "raw_orders", max_depth=4) == []
assert _mod.lineage_paths(cat, "report", "raw_orders", max_depth=5) == [
    ["report", "metrics", "joined", "clean_orders", "raw_orders"],
]
assert _mod.lineage_paths(cat, "x", "raw_orders") == []
assert _mod.lineage_paths(cat, "report", "y") == []

assert _mod.transformation_rules(cat, "joined") == ["join", "join"]
assert _mod.transformation_rules(cat, "report") == ["publish"]
assert _mod.transformation_rules(cat, "raw_orders") == []
assert _mod.transformation_rules(cat, "missing") == []

assert _mod.downstream_volume(cat, "raw_orders") == 1700
assert _mod.downstream_volume(cat, "joined") == 300
assert _mod.downstream_volume(cat, "report") == 0
assert _mod.downstream_volume(cat, "missing") == 0

diamond = _mod.load_lineage_catalog(
    [
        ("hub", "silver", 10),
        ("left", "silver", 20),
        ("right", "silver", 30),
        ("join", "silver", 40),
        ("bronze_a", "bronze", 100),
        ("bronze_b", "bronze", 200),
    ],
    [
        ("right", "join", "join", 0.9, 10),
        ("left", "join", "join", 0.9, 10),
        ("hub", "right", "join", 0.9, 10),
        ("hub", "left", "join", 0.9, 10),
        ("join", "bronze_b", "sink", 0.9, 10),
        ("join", "bronze_a", "sink", 0.9, 10),
    ],
)
print("iss_Sirivennela-ANW__Epics_userstories__46 ref OK")
