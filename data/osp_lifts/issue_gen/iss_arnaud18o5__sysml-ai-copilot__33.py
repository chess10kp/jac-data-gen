"""arnaud18o5/sysml-ai-copilot#33 — impact analysis over SysML element relationships.

Hand-rolled adjacency dicts and deque-BFS traverse CONNECTS_TO, TYPED_BY, and
SATISFIES with every edge treated as undirected (the TYPED_BY backward hop
floods sibling usages that share a type).
"""

from __future__ import annotations

from collections import deque


def load_element_graph(
    elements: list[str],
    typed_by: list[tuple[str, str]],
    connects_to: list[tuple[str, str]],
    satisfies: list[tuple[str, str]],
) -> dict[str, object]:
    adj: dict[str, list[str]] = {eid: [] for eid in elements}

    def _link(a: str, b: str) -> None:
        if a in adj and b in adj and b not in adj[a]:
            adj[a].append(b)

    for usage, typ in typed_by:
        _link(usage, typ)
        _link(typ, usage)
    for left, right in connects_to:
        _link(left, right)
        _link(right, left)
    for left, right in satisfies:
        _link(left, right)
        _link(right, left)
    return {"elements": list(elements), "adj": adj}


def impact_analysis(
    g: dict[str, object],
    element_id: str,
    *,
    max_depth: int = 3,
) -> list[str]:
    adj: dict[str, list[str]] = g["adj"]  # type: ignore[assignment]
    if element_id not in adj:
        return []
    seen: set[str] = {element_id}
    found: set[str] = set()
    queue: deque[tuple[str, int]] = deque([(element_id, 0)])
    while queue:
        cur, depth = queue.popleft()
        if depth >= max_depth:
            continue
        for nb in sorted(adj.get(cur, [])):
            if nb in seen:
                continue
            seen.add(nb)
            found.add(nb)
            queue.append((nb, depth + 1))
    return sorted(found)


def impact_paths(
    g: dict[str, object],
    element_id: str,
    target: str,
    *,
    max_depth: int = 3,
) -> list[list[str]]:
    adj: dict[str, list[str]] = g["adj"]  # type: ignore[assignment]
    if element_id not in adj or target not in adj:
        return []
    out: list[list[str]] = []
    stack: list[tuple[str, list[str]]] = [(element_id, [element_id])]
    while stack:
        node, trail = stack.pop()
        if node == target:
            out.append(trail)
            continue
        if len(trail) >= max_depth:
            continue
        for nxt in sorted(adj.get(node, [])):
            if nxt not in trail:
                stack.append((nxt, trail + [nxt]))
    return sorted(out)
