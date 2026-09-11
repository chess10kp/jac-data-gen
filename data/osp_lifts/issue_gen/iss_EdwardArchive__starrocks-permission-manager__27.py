"""Data lineage DAG for StarRocks VIEW/MV dependencies.

EdwardArchive/starrocks-permission-manager#27: parse VIEW and MATERIALIZED VIEW
definitions into a dependency graph, then answer single-level sources (Phase 1)
and bounded transitive upstream / full downstream impact (Phase 2). Circular
MV refresh chains need explicit cycle detection. The catalog is hand-rolled
adjacency dicts walked by deque breadth-first loops with visited sets.
"""

from collections import deque

MAX_LINEAGE_DEPTH = 5


def build_catalog(objects, refs):
    """Catalog from (fqn, kind) objects and (dependent, source) ref pairs.

    kind is TABLE, VIEW, or MV. Unknown refs in either endpoint are skipped.
    """
    upstream = {fqn: [] for fqn, _ in objects}
    downstream = {fqn: [] for fqn, _ in objects}
    kinds = {fqn: kind for fqn, kind in objects}
    for dependent, source in refs:
        if dependent in upstream and source in upstream:
            if source not in upstream[dependent]:
                upstream[dependent].append(source)
                downstream[source].append(dependent)
    return {"upstream": upstream, "downstream": downstream, "kinds": kinds}


def direct_sources(catalog, fqn):
    """Phase-1 MVP: immediate upstream refs for a VIEW/MV, sorted."""
    upstream = catalog["upstream"]
    if fqn not in upstream:
        return []
    return sorted(upstream[fqn])


def upstream_lineage(catalog, fqn, max_depth=MAX_LINEAGE_DEPTH):
    """Transitive upstream closure within ``max_depth`` hops, sorted."""
    upstream = catalog["upstream"]
    if fqn not in upstream:
        return []
    seen = set()
    queue = deque([(fqn, 0)])
    while queue:
        cur, depth = queue.popleft()
        if depth >= max_depth:
            continue
        for src in list(upstream.get(cur, [])):
            if src not in seen:
                seen.add(src)
                queue.append((src, depth + 1))
    return sorted(seen)


def downstream_impact(catalog, fqn):
    """All transitive dependents (impact analysis), sorted."""
    downstream = catalog["downstream"]
    if fqn not in downstream:
        return []
    seen = set()
    queue = deque([fqn])
    while queue:
        cur = queue.popleft()
        for dep in list(downstream.get(cur, [])):
            if dep not in seen:
                seen.add(dep)
                queue.append(dep)
    return sorted(seen)


def has_circular_mv(catalog):
    """True when any directed cycle is reachable from an MV root."""
    upstream = catalog["upstream"]
    kinds = catalog["kinds"]
    WHITE, GRAY, BLACK = 0, 1, 2
    color = {}

    def dfs(node):
        color[node] = GRAY
        for nb in list(upstream.get(node, [])):
            if nb not in kinds:
                continue
            state = color.get(nb, WHITE)
            if state == GRAY:
                return True
            if state == WHITE and dfs(nb):
                return True
        color[node] = BLACK
        return False

    for fqn in sorted(kinds):
        if kinds[fqn] != "MV":
            continue
        if color.get(fqn, WHITE) == WHITE and dfs(fqn):
            return True
    return False
