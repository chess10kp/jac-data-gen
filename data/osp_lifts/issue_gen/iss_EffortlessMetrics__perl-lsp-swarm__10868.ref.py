"""Reference harness for iss_EffortlessMetrics__perl-lsp-swarm__10868."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__10868.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
canonical_edge_set = _mod.canonical_edge_set
is_blocked_source = _mod.is_blocked_source
liveness_closure = _mod.liveness_closure
project_exact_edges = _mod.project_exact_edges

FACTS = {
    "o_root": {"exec_id": "root", "root_id": "R1", "generation": 3},
    "o_a": {"exec_id": "_a", "root_id": "R1", "generation": 3},
    "o_b": {"exec_id": "_b", "root_id": "R1", "generation": 3},
    "o_anon": {"exec_id": "anon::1", "root_id": "R1", "generation": 3},
    "t_a": {"exec_id": "_a", "root_id": "R1", "generation": 3},
    "t_b": {"exec_id": "_b", "root_id": "R1", "generation": 3},
    "t_pkg1_foo": {"exec_id": "Pkg1::foo", "root_id": "R1", "generation": 3},
    "t_pkg2_foo": {"exec_id": "Pkg2::foo", "root_id": "R1", "generation": 3},
    "o_pkg1": {"exec_id": "Pkg1::caller", "root_id": "R1", "generation": 3},
    "o_other_root": {"exec_id": "shadow", "root_id": "R2", "generation": 3},
    "t_other_root": {"exec_id": "shadow", "root_id": "R2", "generation": 3},
}

CHAIN_OCCS = [
    {
        "occurrence_id": "c1",
        "owner_id": "o_root",
        "target_id": "t_a",
        "kind": "direct_call",
        "root_id": "R1",
        "generation": 3,
        "source_kind": "canonical",
    },
    {
        "occurrence_id": "c2",
        "owner_id": "o_a",
        "target_id": "t_b",
        "kind": "direct_call",
        "root_id": "R1",
        "generation": 3,
        "source_kind": "canonical",
    },
]

CYCLE_OCCS = [
    {
        "occurrence_id": "cy1",
        "owner_id": "o_a",
        "target_id": "t_b",
        "kind": "direct_call",
        "root_id": "R1",
        "generation": 3,
        "source_kind": "canonical",
    },
    {
        "occurrence_id": "cy2",
        "owner_id": "o_b",
        "target_id": "t_a",
        "kind": "direct_call",
        "root_id": "R1",
        "generation": 3,
        "source_kind": "canonical",
    },
]

assert is_blocked_source("ref-source") is True
assert is_blocked_source("canonical") is False

chain_edges = project_exact_edges(CHAIN_OCCS, FACTS)
assert canonical_edge_set(chain_edges) == [
    ("_a", "_b", "direct_call", "c2", "R1", 3, "canonical"),
    ("root", "_a", "direct_call", "c1", "R1", 3, "canonical"),
]
assert liveness_closure("root", chain_edges) == {"root", "_a", "_b"}

cycle_edges = project_exact_edges(CYCLE_OCCS, FACTS)
assert canonical_edge_set(cycle_edges) == [
    ("_a", "_b", "direct_call", "cy1", "R1", 3, "canonical"),
    ("_b", "_a", "direct_call", "cy2", "R1", 3, "canonical"),
]
assert liveness_closure("_a", cycle_edges) == {"_a", "_b"}
assert liveness_closure("_b", cycle_edges) == {"_a", "_b"}

anon_edges = project_exact_edges(
    [
        {
            "occurrence_id": "an1",
            "owner_id": "o_anon",
            "target_id": "t_b",
            "kind": "coderef_capture",
            "root_id": "R1",
            "generation": 3,
            "source_kind": "canonical",
        }
    ],
    FACTS,
)
assert canonical_edge_set(anon_edges) == [
    ("anon::1", "_b", "coderef_capture", "an1", "R1", 3, "canonical")
]

qualified_edges = project_exact_edges(
    [
        {
            "occurrence_id": "q1",
            "owner_id": "o_pkg1",
            "target_id": "t_pkg1_foo",
            "kind": "qualified_call",
            "root_id": "R1",
            "generation": 3,
            "source_kind": "canonical",
        },
        {
            "occurrence_id": "q2",
            "owner_id": "o_pkg1",
            "target_id": "t_pkg2_foo",
            "kind": "qualified_call",
            "root_id": "R1",
            "generation": 3,
            "source_kind": "canonical",
        },
    ],
    FACTS,
)
assert canonical_edge_set(qualified_edges) == [
    ("Pkg1::caller", "Pkg1::foo", "qualified_call", "q1", "R1", 3, "canonical"),
    ("Pkg1::caller", "Pkg2::foo", "qualified_call", "q2", "R1", 3, "canonical"),
]

assert project_exact_edges(
    [
        {
            "occurrence_id": "dyn1",
            "owner_id": "o_a",
            "target_id": "t_b",
            "kind": "dynamic_method",
            "root_id": "R1",
            "generation": 3,
            "source_kind": "canonical",
        }
    ],
    FACTS,
) == []

assert project_exact_edges(
    [
        {
            "occurrence_id": "xr1",
            "owner_id": "o_root",
            "target_id": "t_other_root",
            "kind": "direct_call",
            "root_id": "R1",
            "generation": 3,
            "source_kind": "canonical",
        }
    ],
    FACTS,
) == []

assert project_exact_edges(
    [
        {
            "occurrence_id": "st1",
            "owner_id": "o_root",
            "target_id": "t_a",
            "kind": "direct_call",
            "root_id": "R1",
            "generation": 2,
            "source_kind": "canonical",
        }
    ],
    FACTS,
) == []

assert project_exact_edges(
    [
        {
            "occurrence_id": "blk1",
            "owner_id": "o_root",
            "target_id": "t_a",
            "kind": "direct_call",
            "root_id": "R1",
            "generation": 3,
            "source_kind": "ref-source",
        }
    ],
    FACTS,
) == []

perm_a = project_exact_edges(list(reversed(CHAIN_OCCS)), FACTS)
perm_b = project_exact_edges(list(CHAIN_OCCS), FACTS)
assert canonical_edge_set(perm_a) == canonical_edge_set(perm_b)

diamond_a = [
    {"owner": "root", "target": "_a"},
    {"owner": "root", "target": "_b"},
    {"owner": "_a", "target": "_c"},
    {"owner": "_b", "target": "_c"},
]
diamond_b = [
    {"owner": "_b", "target": "_c"},
    {"owner": "_a", "target": "_c"},
    {"owner": "root", "target": "_b"},
    {"owner": "root", "target": "_a"},
]
assert liveness_closure("root", diamond_a) == liveness_closure("root", diamond_b) == {
    "root",
    "_a",
    "_b",
    "_c",
}

cycle_order_a = [
    {"owner": "_a", "target": "_b"},
    {"owner": "_b", "target": "_a"},
]
cycle_order_b = list(reversed(cycle_order_a))
assert liveness_closure("_a", cycle_order_a) == liveness_closure("_a", cycle_order_b)
print("iss_EffortlessMetrics__perl-lsp-swarm__10868 ref OK")
