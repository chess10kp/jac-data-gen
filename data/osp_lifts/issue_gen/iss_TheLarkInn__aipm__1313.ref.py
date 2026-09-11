"""Reference harness for iss_TheLarkInn__aipm__1313."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_TheLarkInn__aipm__1313.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
from iss_TheLarkInn__aipm__1313 import (
    duplicate_lineage_crates,
    feature_lineage,
    fork_paths,
    heaviest_fork,
    lineage_nodes,
)

nodes = lineage_nodes("aipm")
assert nodes == [
    "aipm",
    "aws-lc-sys",
    "jsonschema",
    "libgit2-sys",
    "reqwest",
    "rustls-aws",
    "rustls-ring",
    "syn",
]

paths = fork_paths("aipm")
assert ["aipm", "jsonschema", "reqwest", "rustls-aws", "aws-lc-sys"] in paths
assert ["aipm", "jsonschema", "reqwest", "rustls-ring"] in paths
assert ["aipm", "libgit2-sys"] in paths
assert ["aipm", "syn"] in paths

assert feature_lineage("jsonschema") == ["reqwest", "resolve-http", "tls-aws-lc-rs"]
assert feature_lineage("rustls-aws") == ["aws-lc-rs", "tls12"]

heavy = heaviest_fork("aipm")
assert heavy == ["aipm", "jsonschema", "reqwest", "rustls-aws", "aws-lc-sys"]

dups = duplicate_lineage_crates(
    [
        ("thiserror", "v1.0.69"),
        ("thiserror", "v2.0.18"),
        ("fastrand", "v2.3.0"),
        ("fastrand", "v2.3.0"),
        ("tower", "v0.4.13"),
        ("tower", "v0.5.3"),
    ]
)
assert dups == {"thiserror": ["v1.0.69", "v2.0.18"], "tower": ["v0.4.13", "v0.5.3"]}
print("iss_TheLarkInn__aipm__1313 ref OK")
