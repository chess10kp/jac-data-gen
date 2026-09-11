"""Reference harness for iss_dasomel__beluga__72."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_dasomel__beluga__72.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
def _fixture() -> TransformationGraph:
    return load_transformation_graph(
        [
            ("bronze_orders", "bronze", "batch_sql", {"scale": "large"}),
            ("bronze_events", "bronze", "streaming", {"stateful": True, "scale": "large"}),
            ("silver_clean", "silver", "quality_remediation", {"scale": "medium"}),
            ("silver_enrich", "silver", "enrichment", {"stateful": True, "scale": "large"}),
            ("silver_joined", "silver", "enrichment", {"scale": "medium"}),
            ("gold_metrics", "gold", "aggregation", {"scale": "large"}),
            ("gold_report", "gold", "gold_publish", {"scale": "large"}),
        ],
        [
            ("silver_clean", "bronze_orders"),
            ("silver_enrich", "bronze_events"),
            ("silver_joined", "silver_clean"),
            ("silver_joined", "silver_enrich"),
            ("gold_metrics", "silver_joined"),
            ("gold_report", "gold_metrics"),
        ],
    )


g = _fixture()

assert select_engine("streaming", stateful=True) == "flink"
assert select_engine("lightweight_sql", bounded=True) == "duckdb"
assert select_engine("batch_sql", scale="large") == "trino"
assert select_engine("aggregation", scale="small") == "airflow_sql"
assert select_engine("gold_publish", scale="large") == "trino"

assert engine_for_transform(g, "bronze_orders") == "trino"
assert engine_for_transform(g, "bronze_events") == "flink"
assert engine_for_transform(g, "silver_enrich") == "flink"
assert engine_for_transform(g, "silver_clean") == "airflow_sql"
assert engine_for_transform(g, "gold_report") == "trino"
assert engine_for_transform(g, "missing") is None

assert upstream_transforms(g, "silver_joined") == [
    "bronze_events",
    "bronze_orders",
    "silver_clean",
    "silver_enrich",
]
assert upstream_transforms(g, "bronze_orders") == []
assert upstream_transforms(g, "bad") == []

assert downstream_consumers(g, "bronze_orders") == [
    "gold_metrics",
    "gold_report",
    "silver_clean",
    "silver_joined",
]
assert downstream_consumers(g, "gold_report") == []
assert downstream_consumers(g, "bad") == []

assert lineage_paths(g, "gold_report", "bronze_orders") == [
    ["gold_report", "gold_metrics", "silver_joined", "silver_clean", "bronze_orders"],
]
assert lineage_paths(g, "gold_report", "bronze_events") == [
    ["gold_report", "gold_metrics", "silver_joined", "silver_enrich", "bronze_events"],
]
assert lineage_paths(g, "silver_joined", "bronze_orders") == [
    ["silver_joined", "silver_clean", "bronze_orders"],
]
assert lineage_paths(g, "gold_report", "bronze_orders", max_depth=4) == []
assert lineage_paths(g, "gold_report", "bronze_orders", max_depth=5) == [
    ["gold_report", "gold_metrics", "silver_joined", "silver_clean", "bronze_orders"],
]
assert lineage_paths(g, "x", "bronze_orders") == []
assert lineage_paths(g, "gold_report", "y") == []

diamond = load_transformation_graph(
    [
        ("hub", "silver", "enrichment", {"scale": "medium"}),
        ("left", "silver", "batch_sql", {"scale": "medium"}),
        ("right", "silver", "batch_sql", {"scale": "medium"}),
        ("join", "silver", "aggregation", {"scale": "medium"}),
        ("bronze_a", "bronze", "batch_sql", {"scale": "large"}),
        ("bronze_b", "bronze", "batch_sql", {"scale": "large"}),
    ],
    [
        ("hub", "left"),
        ("hub", "right"),
        ("left", "join"),
        ("right", "join"),
        ("join", "bronze_a"),
        ("join", "bronze_b"),
    ],
)
assert lineage_paths(diamond, "hub", "bronze_a") == [
    ["hub", "left", "join", "bronze_a"],
    ["hub", "right", "join", "bronze_a"],
]
assert upstream_transforms(diamond, "hub") == ["bronze_a", "bronze_b", "join", "left", "right"]

cycle = load_transformation_graph(
    [
        ("a", "silver", "batch_sql", {"scale": "medium"}),
        ("b", "silver", "batch_sql", {"scale": "medium"}),
        ("c", "silver", "batch_sql", {"scale": "medium"}),
    ],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert upstream_transforms(cycle, "a") == ["b", "c"]
assert lineage_paths(cycle, "a", "a") == [["a"]]
assert lineage_paths(cycle, "a", "c", max_depth=2) == []
assert lineage_paths(cycle, "a", "c", max_depth=3) == [["a", "b", "c"]]
print("iss_dasomel__beluga__72 ref OK")
