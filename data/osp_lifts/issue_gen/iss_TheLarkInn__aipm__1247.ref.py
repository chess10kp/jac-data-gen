"""Reference harness for iss_TheLarkInn__aipm__1247."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_TheLarkInn__aipm__1247.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
G = _mod.load_build_graph(
    [
        ("aws-lc-sys", 91.5),
        ("libgit2-sys", 72.8),
        ("syn", 27.8),
        ("rustls@ring", 23.8),
        ("jsonschema", 22.7),
        ("rustls@aws-lc-rs", 22.6),
        ("reqwest", 19.9),
        ("serde_derive", 12.9),
        ("clap_derive", 5.0),
        ("thiserror-impl", 4.0),
        ("tokio-macros", 3.0),
        ("bitflags@1.3.2", 1.0),
        ("bitflags@2.11.0", 1.0),
        ("lsp-types", 2.0),
        ("tower-lsp", 8.0),
        ("workspace", 0.0),
    ],
    [
        ("jsonschema", "reqwest"),
        ("reqwest", "rustls@aws-lc-rs"),
        ("rustls@aws-lc-rs", "aws-lc-sys"),
        ("reqwest", "rustls@ring"),
        ("workspace", "jsonschema"),
        ("workspace", "syn"),
        ("workspace", "tower-lsp"),
        ("workspace", "bitflags@2.11.0"),
        ("serde_derive", "syn"),
        ("clap_derive", "syn"),
        ("thiserror-impl", "syn"),
        ("tokio-macros", "syn"),
        ("tower-lsp", "lsp-types"),
        ("lsp-types", "bitflags@1.3.2"),
    ],
)

assert _mod.transitive_deps(G, "jsonschema") == [
    "aws-lc-sys",
    "reqwest",
    "rustls@aws-lc-rs",
    "rustls@ring",
]
assert _mod.downstream_units(G, "syn") == [
    "clap_derive",
    "serde_derive",
    "thiserror-impl",
    "tokio-macros",
    "workspace",
]
assert _mod.duplicate_base_names(G) == ["bitflags", "rustls"]
assert _mod.dependency_paths(G, "jsonschema", "aws-lc-sys") == [
    ["jsonschema", "reqwest", "rustls@aws-lc-rs", "aws-lc-sys"],
]
assert _mod.slowest_units(G, 20.0) == [
    ("aws-lc-sys", 91.5),
    ("libgit2-sys", 72.8),
    ("syn", 27.8),
    ("rustls@ring", 23.8),
    ("jsonschema", 22.7),
    ("rustls@aws-lc-rs", 22.6),
]

assert _mod.transitive_deps(G, "missing") == []
assert _mod.downstream_units(G, "ghost") == []
assert _mod.dependency_paths(G, "jsonschema", "missing") == []
assert _mod.dependency_paths(G, "jsonschema", "aws-lc-sys", max_depth=3) == []

CYC = _mod.load_build_graph(
    [("a", 1.0), ("b", 1.0), ("c", 1.0), ("leaf", 1.0)],
    [("a", "b"), ("b", "c"), ("c", "a"), ("c", "leaf")],
)
assert _mod.transitive_deps(CYC, "a") == ["b", "c", "leaf"]

DIAM = _mod.load_build_graph(
    [("root", 0.0), ("left", 0.0), ("right", 0.0), ("sink", 0.0)],
    [
        ("root", "right"),
        ("root", "left"),
        ("right", "sink"),
        ("left", "sink"),
    ],
)
assert _mod.dependency_paths(DIAM, "root", "sink") == [
    ["root", "left", "sink"],
    ["root", "right", "sink"],
]

REV = _mod.load_build_graph(
    [("a", 1.0), ("b", 1.0), ("c", 1.0), ("d", 1.0)],
    [("a", "b"), ("b", "c"), ("c", "a"), ("d", "b")],
)
assert _mod.downstream_units(REV, "c") == ["a", "b", "d"]
print("iss_TheLarkInn__aipm__1247 ref OK")
