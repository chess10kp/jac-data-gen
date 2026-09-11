"""Reference harness for iss_acryldata__mcp-server-datahub__152."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_acryldata__mcp-server-datahub__152.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
reg = _mod.load_lineage_registry(
    [
        ("urn:ds.ingest", "bronze", 1),
        ("urn:ds.raw", "bronze", 2),
        ("urn:ds.clean", "silver", 3),
        ("urn:ds.orders", "gold", 4),
        ("urn:col.id", "column", 5),
    ],
    [
        ("urn:ds.ingest", "urn:ds.raw"),
        ("urn:ds.raw", "urn:ds.clean"),
        ("urn:ds.clean", "urn:ds.orders"),
        ("urn:ds.orders", "urn:col.id"),
    ],
    [
        (
            "urn:ds.orders",
            [
                "order_id",
                "customer_id",
                "amount",
                "currency",
                "status",
                "created_at",
                "updated_at",
                "region",
            ],
        ),
    ],
    telemetry_enabled=True,
)
assert _mod.list_schema_fields(reg, "urn:ds.orders") == [
    "amount",
    "created_at",
    "currency",
    "customer_id",
    "order_id",
    "region",
    "status",
    "updated_at",
]
assert _mod.get_lineage(reg, "urn:col.id") == [
    "urn:ds.clean",
    "urn:ds.ingest",
    "urn:ds.orders",
    "urn:ds.raw",
]
assert _mod.get_lineage(reg, "urn:ds.ingest", direction="downstream") == [
    "urn:col.id",
    "urn:ds.clean",
    "urn:ds.orders",
    "urn:ds.raw",
]

reg = _mod.load_lineage_registry(
    [("urn:ds.orders", "gold", 4)],
    [],
    [("urn:ds.orders", ["order_id"])],
    telemetry_enabled=False,
)
assert _mod.get_lineage(reg, "missing") == []
assert _mod.list_schema_fields(reg, "missing") == []
assert _mod.get_lineage_paths_between(reg, "ghost", "urn:ds.orders") == []
assert _mod.get_lineage_paths_between(reg, "urn:ds.orders", "ghost") == []

reg = _mod.load_lineage_registry(
    [
        ("urn:ds.ingest", "bronze", 1),
        ("urn:ds.raw", "bronze", 2),
        ("urn:ds.clean", "silver", 3),
        ("urn:ds.orders", "gold", 4),
        ("urn:col.id", "column", 5),
    ],
    [
        ("urn:ds.ingest", "urn:ds.raw"),
        ("urn:ds.raw", "urn:ds.clean"),
        ("urn:ds.clean", "urn:ds.orders"),
        ("urn:ds.orders", "urn:col.id"),
    ],
    [],
    telemetry_enabled=False,
)
assert _mod.get_lineage_paths_between(reg, "urn:col.id", "urn:ds.ingest") == [
    [
        "urn:col.id",
        "urn:ds.orders",
        "urn:ds.clean",
        "urn:ds.raw",
        "urn:ds.ingest",
    ],
]
assert _mod.get_lineage_paths_between(reg, "urn:col.id", "urn:ds.ingest", max_depth=4) == []
assert _mod.get_lineage_paths_between(reg, "urn:col.id", "urn:col.id") == [["urn:col.id"]]

slow = _mod.load_lineage_registry(
    [("urn:col.id", "column", 5)],
    [],
    [],
    telemetry_enabled=True,
)
assert _mod.per_call_latency_ms(slow, "list_schema_fields") == 54090
assert _mod.bulk_paths_stall_ms(
    slow,
    [
        ("urn:col.id", "urn:ds.raw"),
        ("urn:col.id", "urn:ds.ingest"),
    ],
) == 108180

fast = _mod.load_lineage_registry(
    [("urn:col.id", "column", 5)],
    [],
    [],
    telemetry_enabled=False,
)
assert _mod.bulk_paths_stall_ms(
    fast,
    [
        ("urn:col.id", "urn:ds.raw"),
        ("urn:col.id", "urn:ds.ingest"),
        ("urn:col.id", "urn:ds.clean"),
    ],
) == 270

diamond = _mod.load_lineage_registry(
    [
        ("urn:hub", "silver", 10),
        ("urn:left", "silver", 20),
        ("urn:right", "silver", 30),
        ("urn:join", "silver", 40),
        ("urn:bronze_a", "bronze", 100),
        ("urn:bronze_b", "bronze", 200),
    ],
    [
        ("urn:bronze_b", "urn:join"),
        ("urn:bronze_a", "urn:join"),
        ("urn:join", "urn:right"),
        ("urn:join", "urn:left"),
        ("urn:right", "urn:hub"),
        ("urn:left", "urn:hub"),
    ],
    [],
    telemetry_enabled=False,
)
assert _mod.get_lineage_paths_between(diamond, "urn:hub", "urn:bronze_a") == [
    ["urn:hub", "urn:left", "urn:join", "urn:bronze_a"],
    ["urn:hub", "urn:right", "urn:join", "urn:bronze_a"],
]
assert _mod.get_lineage_paths_between(diamond, "urn:hub", "urn:bronze_b") == [
    ["urn:hub", "urn:left", "urn:join", "urn:bronze_b"],
    ["urn:hub", "urn:right", "urn:join", "urn:bronze_b"],
]
print("iss_acryldata__mcp-server-datahub__152 ref OK")
