"""banso-labs/banso#588 — Reachability index for blast-radius forward impact.

Hand-rolled call-graph adjacency with BFS reachability and ancestor chain
lookup backing is_reachable and forward_reachable queries.
"""

from __future__ import annotations

from collections import deque


class CallGraph:
    def __init__(self) -> None:
        self.nodes: set[str] = set()
        self.calls: dict[str, list[str]] = {}
        self.caller: dict[str, str] = {}


def load_call_graph(
    nodes: list[str],
    calls: list[tuple[str, str]],
) -> CallGraph:
    g = CallGraph()
    for n in nodes:
        g.nodes.add(n)
        g.calls.setdefault(n, [])
    for src, dst in calls:
        if src in g.nodes and dst in g.nodes:
            g.calls[src].append(dst)
            g.caller[dst] = src
    return g


def _bfs_reachable(g: CallGraph, seed: str, max_depth: int) -> set[str]:
    if seed not in g.nodes:
        return set()
    seen: set[str] = {seed}
    q: deque[tuple[str, int]] = deque([(seed, 0)])
    while q:
        cur, depth = q.popleft()
        if depth >= max_depth:
            continue
        for nxt in g.calls.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                q.append((nxt, depth + 1))
    return seen


def forward_reachable(g: CallGraph, seed: str, max_depth: int) -> list[str]:
    return sorted(_bfs_reachable(g, seed, max_depth))


def is_reachable(g: CallGraph, src: str, dst: str) -> bool:
    if src not in g.nodes or dst not in g.nodes:
        return False
    return dst in _bfs_reachable(g, src, 64)


def caller_chain(g: CallGraph, node_id: str) -> list[str]:
    if node_id not in g.nodes:
        return []
    chain: list[str] = [node_id]
    claimed: set[str] = {node_id}
    cur = node_id
    while True:
        parent = g.caller.get(cur)
        if parent is None or parent in claimed:
            break
        claimed.add(parent)
        chain.append(parent)
        cur = parent
    return chain
