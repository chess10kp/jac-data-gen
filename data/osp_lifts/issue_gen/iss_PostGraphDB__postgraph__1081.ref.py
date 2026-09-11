"""Reference harness for iss_PostGraphDB__postgraph__1081."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_PostGraphDB__postgraph__1081.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
g = _mod.make_storage()
for vid, props, vec in [
    ("root", {"label": "root"}, (0.0, 0.0)),
    ("left", {"label": "branch"}, (1.0, 0.0)),
    ("right", {"label": "branch"}, (0.0, 1.0)),
    ("join", {"label": "leaf"}, (1.0, 1.0)),
]:
    _mod.add_vertex(g, vid, props, vec)

_mod.add_edge(g, "e_r", "root", "right", {"kind": "tree"})
_mod.add_edge(g, "e_jr", "right", "join", {"kind": "merge"})
_mod.add_edge(g, "e_l", "root", "left", {"kind": "tree"})
_mod.add_edge(g, "e_jl", "left", "join", {"kind": "merge"})

assert _mod.adjacency_neighbors(g, "root") == ["left", "right"]
assert _mod.heap_scan_neighbors(g, "root") == ["left", "right"]
assert _mod.storage_views_agree(g, "root") is True
assert _mod.bfs_reachable(g, "root", 1) == ["left", "right"]
assert _mod.bfs_reachable(g, "root", 2) == ["join", "left", "right"]
assert _mod.bfs_edge_property_refs(g, "root", 2) == ["e_jl", "e_jr", "e_l", "e_r"]
assert _mod.neighbors_matching_edge_prop(g, "root", "kind", "tree") == ["left", "right"]
assert _mod.neighbors_matching_edge_prop(g, "left", "kind", "merge") == ["join"]
assert _mod.vector_knn(g, (1.0, 1.0), 1) == ["join"]
assert _mod.vector_knn(g, (1.0, 1.0), 2) == ["join", "left"]

shuffled = _mod.make_storage()
for vid, props, vec in [
    ("join", {"label": "leaf"}, (1.0, 1.0)),
    ("right", {"label": "branch"}, (0.0, 1.0)),
    ("root", {"label": "root"}, (0.0, 0.0)),
    ("left", {"label": "branch"}, (1.0, 0.0)),
]:
    _mod.add_vertex(shuffled, vid, props, vec)
_mod.add_edge(shuffled, "e_r", "root", "right", {"kind": "tree"})
_mod.add_edge(shuffled, "e_jr", "right", "join", {"kind": "merge"})
_mod.add_edge(shuffled, "e_l", "root", "left", {"kind": "tree"})
_mod.add_edge(shuffled, "e_jl", "left", "join", {"kind": "merge"})
assert _mod.bfs_reachable(shuffled, "root", 2) == ["join", "left", "right"]
assert _mod.storage_views_agree(shuffled, "join") is True

cycle = _mod.make_storage()
for vid in ("a", "b", "c"):
    _mod.add_vertex(cycle, vid, {"n": vid}, (0.0, 0.0))
_mod.add_edge(cycle, "e1", "a", "b", {"rel": "next"})
_mod.add_edge(cycle, "e2", "b", "c", {"rel": "next"})
_mod.add_edge(cycle, "e3", "c", "a", {"rel": "next"})
assert _mod.bfs_reachable(cycle, "a", 5) == ["b", "c"]
assert _mod.bfs_edge_property_refs(cycle, "a", 5) == ["e1", "e2", "e3"]

assert _mod.adjacency_neighbors(g, "ghost") == []
assert _mod.heap_scan_neighbors(g, "ghost") == []
assert _mod.bfs_reachable(g, "ghost", 3) == []
assert _mod.bfs_edge_property_refs(g, "ghost", 3) == []
assert _mod.neighbors_matching_edge_prop(g, "ghost", "kind", "tree") == []
assert _mod.storage_views_agree(g, "ghost") is True
assert _mod.vector_knn(_mod.make_storage(), (0.0, 0.0), 3) == []

try:
    _mod.add_edge(g, "bad", "ghost", "root", {"kind": "tree"})
    raise AssertionError("expected KeyError")
except KeyError:
    pass
print("iss_PostGraphDB__postgraph__1081 ref OK")
