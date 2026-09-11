"""Reference harness for EffortlessMetrics/cargo-allow#3902."""

import importlib.util
from pathlib import Path

_MOD = Path(__file__).with_name("iss_EffortlessMetrics__cargo-allow__3902.py")
_spec = importlib.util.spec_from_file_location("cargo_allow_3902_mod", _MOD)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

load_evidence = _mod.load_evidence
evidence_waves = _mod.evidence_waves
upstream_closure = _mod.upstream_closure

CLAIMS = [
    "rust_edition",
    "resolver3",
    "msrv_proof",
    "lockfile_delta",
    "api_compat",
]
REQ = [
    ("resolver3", "rust_edition"),
    ("msrv_proof", "rust_edition"),
    ("lockfile_delta", "resolver3"),
    ("api_compat", "lockfile_delta"),
    ("api_compat", "msrv_proof"),
]

g = load_evidence(CLAIMS, REQ)
assert evidence_waves(g) == [
    ["rust_edition"],
    ["msrv_proof", "resolver3"],
    ["lockfile_delta"],
    ["api_compat"],
]
assert upstream_closure(g, "api_compat") == [
    "lockfile_delta",
    "msrv_proof",
    "resolver3",
    "rust_edition",
]
assert upstream_closure(g, "missing") == []

cycle = load_evidence(["a", "b", "c"], [("a", "b"), ("b", "c"), ("c", "a")])
assert evidence_waves(cycle) is None

diamond = load_evidence(
    ["top", "left", "right", "base", "leaf"],
    [
        ("top", "right"),
        ("base", "leaf"),
        ("left", "base"),
        ("top", "left"),
        ("right", "base"),
    ],
)
assert upstream_closure(diamond, "top") == ["base", "leaf", "left", "right"]

print("cargo-allow 3902 ref OK")
