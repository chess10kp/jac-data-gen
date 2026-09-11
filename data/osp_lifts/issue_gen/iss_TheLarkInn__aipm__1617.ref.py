"""Reference harness for iss_TheLarkInn__aipm__1617."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_TheLarkInn__aipm__1617.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
G = _mod.load_build_report_graph(
    [
        ("workspace", 0.0, False),
        ("libaipm-engine-spec", 0.0, False),
        ("jsonschema", 22.2, False),
        ("reqwest", 19.2, False),
        ("rustls@norm", 21.7, False),
        ("rustls@build", 21.9, False),
        ("aws-lc-sys", 87.4, True),
        ("libgit2-sys", 70.4, True),
        ("syn", 25.4, False),
        ("serde_derive", 12.0, False),
        ("git2", 8.0, False),
        ("semver@lib", 1.0, False),
        ("semver@trans", 1.0, False),
        ("semver-base", 0.5, False),
    ],
    [
        ("workspace", "libaipm-engine-spec", ""),
        ("workspace", "syn", ""),
        ("workspace", "git2", ""),
        ("workspace", "semver@lib", ""),
        ("workspace", "serde_derive", ""),
        ("libaipm-engine-spec", "jsonschema", ""),
        ("jsonschema", "reqwest", "tls-aws-lc-rs"),
        ("reqwest", "rustls@norm", "tls-aws-lc-rs"),
        ("reqwest", "rustls@build", "tls-aws-lc-rs"),
        ("rustls@norm", "aws-lc-sys", "tls-aws-lc-rs"),
        ("git2", "libgit2-sys", "https"),
        ("serde_derive", "syn", ""),
    ],
    [
        ("semver@lib", "semver-base"),
        ("semver@trans", "semver-base"),
    ],
)

assert _mod.memo_ancestors(G, "semver@lib") == ["semver-base"]
assert _mod.memo_ancestors(G, "semver@trans") == ["semver-base"]
assert _mod.memo_ancestors(G, "semver@lib") == _mod.memo_ancestors(G, "semver@lib")
assert _mod.memo_ancestors(G, "missing") == []

assert _mod.transitive_build_deps(G, "workspace") == [
    "aws-lc-sys",
    "git2",
    "jsonschema",
    "libaipm-engine-spec",
    "libgit2-sys",
    "reqwest",
    "rustls@build",
    "rustls@norm",
    "semver@lib",
    "serde_derive",
    "syn",
]
assert _mod.transitive_build_deps(G, "workspace", ["tls-aws-lc-rs"]) == [
    "git2",
    "jsonschema",
    "libaipm-engine-spec",
    "libgit2-sys",
    "semver@lib",
    "serde_derive",
    "syn",
]
assert _mod.transitive_build_deps(G, "ghost") == []

assert _mod.units_blocked_by_trim(G, "workspace", ["tls-aws-lc-rs"]) == [
    "aws-lc-sys",
    "reqwest",
    "rustls@build",
    "rustls@norm",
]
assert _mod.units_blocked_by_trim(G, "workspace", ["https"]) == ["libgit2-sys"]
assert _mod.units_blocked_by_trim(G, "missing", ["tls-aws-lc-rs"]) == []

assert _mod.trim_time_savings(G, "workspace", ["tls-aws-lc-rs"]) == 150.2
assert _mod.trim_time_savings(G, "workspace", ["https"]) == 70.4

assert _mod.build_script_hotspots(G, 60.0) == [
    ("aws-lc-sys", 87.4),
    ("libgit2-sys", 70.4),
]
assert _mod.build_script_hotspots(G, 90.0) == []

DIAM = _mod.load_build_report_graph(
    [
        ("root", 0.0, False),
        ("gate_a", 1.0, False),
        ("mid_a", 2.0, False),
        ("mid_b", 3.0, False),
        ("target", 4.0, False),
    ],
    [
        ("root", "gate_a", "tls-aws-lc-rs"),
        ("gate_a", "mid_a", ""),
        ("mid_a", "target", ""),
        ("root", "mid_b", ""),
        ("mid_b", "target", ""),
    ],
    [],
)
assert _mod.units_blocked_by_trim(DIAM, "root", ["tls-aws-lc-rs"]) == ["gate_a", "mid_a"]
assert _mod.transitive_build_deps(DIAM, "root", ["tls-aws-lc-rs"]) == ["mid_b", "target"]

CYC = _mod.load_build_report_graph(
    [("a", 1.0, False), ("b", 1.0, False), ("c", 1.0, False)],
    [("a", "b", ""), ("b", "c", ""), ("c", "a", "")],
    [],
)
assert _mod.transitive_build_deps(CYC, "a") == ["b", "c"]

LIN_CYC = _mod.load_build_report_graph(
    [("a", 0.0, False), ("b", 0.0, False), ("c", 0.0, False)],
    [],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert _mod.memo_ancestors(LIN_CYC, "a") == ["a", "b", "c"]

print("iss_TheLarkInn__aipm__1617 ref OK")
print("iss_TheLarkInn__aipm__1617 ref OK")
