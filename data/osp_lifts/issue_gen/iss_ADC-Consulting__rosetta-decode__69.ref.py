"""Reference harness for iss_ADC-Consulting__rosetta-decode__69."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_ADC-Consulting__rosetta-decode__69.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

p = _mod.load_pipeline(
    ["export", "aggregate", "join", "filter", "raw_a", "raw_b"],
    [
        ("raw_a", "filter"),
        ("filter", "join"),
        ("raw_b", "join"),
        ("join", "aggregate"),
        ("aggregate", "export"),
    ],
)
assert _mod.upstream_tasks(p, "export") == [
    "aggregate", "filter", "join", "raw_a", "raw_b"
]
assert _mod.lineage_depth(p, "export") == 4
assert _mod.upstream_tasks(p, "missing") == []

print("iss_ADC-Consulting__rosetta-decode__69 ref OK")
