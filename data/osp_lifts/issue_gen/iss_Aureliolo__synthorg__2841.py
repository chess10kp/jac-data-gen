"""Persisting the recursive plan decomposition tree.

Recursive decomposition works: the harness drives plans to depth 3 and
the depth sweep shows it paying off. But the durable plan model is
flat -- ``PlanItem`` carries a sibling ``depends_on`` DAG and no parent
link, no children, no depth -- so a decomposition tree can be produced
and cannot be persisted, and nothing downstream of the planner can act
on one.

``materialize`` closes that gap. Given the decomposition tree the
recursion harness produced (parent -> children) and the flat item map
(id -> depends_on siblings), it emits durable rows -- one per item,
carrying ``id``, ``parent_id`` and ``depth`` -- plus the tree's max
depth. Depth is computed by stack descent from the roots (items that
are no one's child); an item the tree never touches persists with no
parent and no depth. ``dependency_closure`` stays: dispatch order
still comes from the sibling DAG, and it answers the transitive
dependency query by DFS with a visited set over the flat adjacency
(a cycle rides back to its own start).
Ref: Aureliolo/synthorg#2841
"""


def _parent_map(tree):
    """child id -> parent id, from the decomposition tree."""
    parents = {}
    for parent, children in tree.items():
        for child in children:
            parents[child] = parent
    return parents


def _depth_map(tree, parents):
    """item id -> depth, by stack descent from the forest's roots."""
    depth = {}
    ids = list(tree.keys())
    for children in tree.values():
        ids.extend(children)
    roots = [i for i in ids if i not in parents]
    stack = [(r, 0) for r in roots]
    while stack:
        node, d = stack.pop()
        if node in depth:
            continue  # a node keeps its first assigned depth
        depth[node] = d
        for child in tree.get(node, []):
            stack.append((child, d + 1))
    return depth


def materialize(tree, items):
    """Durable rows for the decomposition tree, sorted by item id.

    Returns {"rows": [{"id", "parent_id", "depth"}, ...] sorted by id,
    "max_depth": deepest level in the tree (0 for an empty plan)}.
    """
    parents = _parent_map(tree)
    depth = _depth_map(tree, parents)
    ids = set(tree.keys())
    for children in tree.values():
        ids.update(children)
    ids.update(items.keys())
    rows = [
        {"id": i, "parent_id": parents.get(i), "depth": depth.get(i)}
        for i in sorted(ids)
    ]
    max_depth = max(depth.values()) if depth else 0
    return {"rows": rows, "max_depth": max_depth}


def dependency_closure(items, id):
    """Sorted transitive depends_on ids of ``id`` (DFS, visited set)."""
    if id not in items:
        raise KeyError(f"unknown plan item {id}")
    seen = set()
    stack = list(items[id])
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue  # diamond: a sibling reached twice closes once
        seen.add(cur)
        stack.extend(items.get(cur, []))
    return sorted(seen)
