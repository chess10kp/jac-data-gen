"""Bulk node-deletion impact analysis for a lineage DAG.

DataJunction/dj#2272: deleting a large set of nodes runs one downstream BFS
per node, re-traversing overlapping subgraphs. The fix computes the impact
once for the whole set: the only downstream work that matters is the
boundary -- nodes reachable from the delete set S that are not in S. The
lineage is an in-memory adjacency dict of parent -> [children]; walks are
explicit list-as-frontier breadth-first loops with a visited set.
"""


def build_lineage(nodes, edges):
    """Adjacency dict; edges are (parent, child) pairs of declared nodes."""
    adj = {n: [] for n in nodes}
    for parent, child in edges:
        if parent in adj and child in adj:
            adj[parent].append(child)
    return adj


def downstream_closure(adj, seeds):
    """All nodes reachable from any seed, excluding the seeds themselves.

    Tolerates cycles (visited set) and unknown seed names.
    """
    known = set(seeds) & set(adj)
    seen = set()
    frontier = []
    for s in known:
        frontier.extend(adj[s])
    while frontier:
        cur = frontier.pop()
        if cur in seen or cur in known:
            continue
        seen.add(cur)
        frontier.extend(adj[cur])
    return sorted(seen)


def delete_boundary(adj, seeds):
    """Downstream nodes of the seed set that survive deletion.

    This is the set that needs MissingParent bookkeeping: everything else
    reachable is internal to S and gets deleted wholesale.
    """
    seed_set = {s for s in seeds if s in adj}
    return [n for n in downstream_closure(adj, seeds) if n not in seed_set]


def is_impacted(adj, seeds, node):
    """True when ``node`` sits strictly below at least one seed."""
    if node not in adj or node in {s for s in seeds if s in adj}:
        return False
    return node in set(downstream_closure(adj, seeds))
