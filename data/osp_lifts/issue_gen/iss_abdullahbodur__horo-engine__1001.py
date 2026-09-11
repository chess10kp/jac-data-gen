"""Prefab expansion with deterministic per-instance ID namespacing.

A scene references prefab instances; expansion resolves each instance
against an immutable prefab snapshot (a table of prefab-local node ids
with children lists), namespaces every local id by instance identity as
``inst:<iid>:<local>``, and emits the expanded hierarchy. Resolution fails
closed: an unknown prefab raises ``KeyError`` before any output is
produced, so a failed resolution never yields a partially expanded
candidate. A shared prefab expands once per instance into disjoint ID
spaces, and expanded member references cannot collide with each other.
Local node tables form a hierarchy (each local id has at most one
parent); only nodes reachable from the prefab root expand.
Ref: abdullahbodur/horo-engine#1001
"""


def expand(scene, prefabs):
    """Expand prefab instances into concrete scene nodes and hierarchy edges.

    ``scene`` lists ``{"id": instance_id, "prefab": name}`` instances;
    ``prefabs`` maps name -> ``{"root": local_id, "nodes": {local_id:
    {"children": [ids]}}}``. Returns ``{"nodes": sorted expanded ids,
    "edges": sorted [parent, child] expanded pairs}``; raises ``KeyError``
    on a prefab unknown to the snapshot.
    """
    nodes = set()
    edges = set()
    for inst in scene:
        iid = inst["id"]
        spec = prefabs[inst["prefab"]]  # fail closed: no partial result
        _instantiate(spec["root"], None, iid, spec, nodes, edges)
    return {"nodes": sorted(nodes), "edges": sorted([list(e) for e in edges])}


def _instantiate(local_id, parent_expanded, iid, spec, nodes, edges):
    """Recursive instantiation: remap one local node, then its children."""
    expanded = "inst:" + iid + ":" + local_id
    nodes.add(expanded)
    if parent_expanded is not None:
        edges.add((parent_expanded, expanded))
    for kid in spec["nodes"].get(local_id, {}).get("children", []):
        _instantiate(kid, expanded, iid, spec, nodes, edges)
