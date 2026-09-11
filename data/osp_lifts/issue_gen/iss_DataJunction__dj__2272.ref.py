"""Reference harness: exercises every public function of iss_DataJunction__dj__2272."""
from iss_DataJunction__dj__2272 import (
    build_lineage,
    delete_boundary,
    downstream_closure,
    is_impacted,
)

adj = build_lineage(
    ["ns.tbl_a", "ns.tbl_b", "ns.view", "ns.dash_src", "common.dim", "orphan"],
    [
        ("ns.tbl_a", "ns.view"),
        ("ns.tbl_b", "ns.view"),
        ("ns.view", "ns.dash_src"),
        ("ns.tbl_a", "common.dim"),
    ],
)

# Shared subgraph reached from two seeds must appear exactly once.
assert downstream_closure(adj, ["ns.tbl_a"]) == ["common.dim", "ns.dash_src", "ns.view"]
assert downstream_closure(adj, ["ns.tbl_a", "ns.tbl_b"]) == [
    "common.dim",
    "ns.dash_src",
    "ns.view",
]

# Boundary excludes the seed set itself even when it sits mid-graph.
assert delete_boundary(adj, ["ns.tbl_a"]) == ["common.dim", "ns.dash_src", "ns.view"]
assert delete_boundary(adj, ["ns.tbl_a", "ns.view"]) == ["common.dim", "ns.dash_src"]

assert is_impacted(adj, ["ns.tbl_a"], "ns.dash_src")
assert not is_impacted(adj, ["ns.tbl_a"], "ns.tbl_a")   # seed itself is not impacted
assert not is_impacted(adj, ["ns.tbl_a"], "ns.tbl_b")
assert not is_impacted(adj, ["ns.tbl_a"], "ghost")

# Unknown seeds are ignored; orphans stay out of every result.
leaf = build_lineage(["solo"], [])
assert downstream_closure(leaf, ["solo"]) == []
assert delete_boundary(leaf, ["missing"]) == []
assert not is_impacted(leaf, ["missing"], "solo")

# Lineage cycle: must terminate, seeds excluded once.
cyc = build_lineage(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert downstream_closure(cyc, ["a"]) == ["b", "c"]
assert delete_boundary(cyc, ["a", "b"]) == ["c"]
assert is_impacted(cyc, ["a", "b"], "c")

print("dj 2272 ref OK")
