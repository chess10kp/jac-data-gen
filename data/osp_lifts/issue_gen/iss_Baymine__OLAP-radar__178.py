"""OLAP ecosystem upstream lineage for digest cross-links.

Baymine/OLAP-radar#178: the digest highlights engine work (recursive CTE,
Iceberg lineage) across a multi-repo dependency graph. Upstream closure is
computed with hand-rolled adjacency dicts and a deque BFS that mirrors a
bounded WITH RECURSIVE oracle.
"""

from __future__ import annotations

from collections import deque

MAX_LINEAGE_DEPTH = 5


def build_catalog(components: list[str], refs: list[tuple[str, str]]) -> dict:
    # dependent -> sorted unique upstream sources
    upstream: dict[str, list[str]] = {c: [] for c in components}
    for dependent, source in refs:
        if dependent in upstream and source in upstream:
            if source not in upstream[dependent]:
                upstream[dependent].append(source)
    return {"upstream": upstream, "components": sorted(components)}


def direct_upstream(catalog: dict, name: str) -> list[str]:
    upstream = catalog["upstream"]
    if name not in upstream:
        return []
    return sorted(upstream[name])


def upstream_closure(
    catalog: dict,
    name: str,
    max_depth: int = MAX_LINEAGE_DEPTH,
) -> list[str]:
    # Bounded recursive-CTE oracle: transitive upstream within max_depth hops.
    upstream = catalog["upstream"]
    if name not in upstream:
        return []
    seen: set[str] = set()
    work: deque[tuple[str, int]] = deque([(name, 0)])
    while work:
        cur, depth = work.popleft()
        if depth >= max_depth:
            continue
        for src in list(upstream.get(cur, [])):
            if src not in seen:
                seen.add(src)
                work.append((src, depth + 1))
    return sorted(seen)


def lineage_digest(
    catalog: dict,
    name: str,
    max_depth: int = MAX_LINEAGE_DEPTH,
) -> list[str]:
    # Digest membership: anchor + direct + bounded transitive upstream.
    if name not in catalog["upstream"]:
        return []
    direct = direct_upstream(catalog, name)
    trans = upstream_closure(catalog, name, max_depth)
    return sorted(set([name] + direct + trans))
