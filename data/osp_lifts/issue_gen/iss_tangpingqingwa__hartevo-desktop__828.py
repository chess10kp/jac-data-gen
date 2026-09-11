"""Governed bounded graph-query evidence with digest-only projection.

Source: tangpingqingwa/hartevo-desktop#828.
"""

from __future__ import annotations

from collections import deque

DEFAULT_HOP_BUDGET = 4
DEFAULT_ROW_CAP = 64


def node_digest(label: str) -> str:
    acc = 0
    for ch in label:
        acc = (acc * 31 + ord(ch)) & 0xFFFFFFFF
    return f"d:{acc:08x}"


def _adj(edges: list[tuple[str, str]]) -> dict[str, list[str]]:
    adj: dict[str, list[str]] = {}
    for src, dst in edges:
        adj.setdefault(src, []).append(dst)
        adj.setdefault(dst, [])
    return adj


def governed_reach(
    start: str,
    edges: list[tuple[str, str]],
    hop_budget: int = DEFAULT_HOP_BUDGET,
    row_cap: int = DEFAULT_ROW_CAP,
) -> tuple[str, list[str]]:
    adj = _adj(edges)
    if start not in adj:
        return ("EMPTY", [])
    visited: set[str] = set()
    q: deque[tuple[str, int]] = deque([(start, 0)])
    order: list[str] = []
    truncated = False
    while q:
        node, depth = q.popleft()
        if node in visited:
            continue
        if len(order) >= row_cap:
            truncated = True
            break
        visited.add(node)
        order.append(node)
        if depth >= hop_budget:
            continue
        for nxt in sorted(adj.get(node, [])):
            if nxt not in visited:
                q.append((nxt, depth + 1))
    if not order:
        return ("EMPTY", [])
    status = "PARTIAL" if truncated else "PRESENT"
    return (status, sorted(node_digest(n) for n in order))


def within_budget(
    start: str,
    edges: list[tuple[str, str]],
    hop_budget: int = DEFAULT_HOP_BUDGET,
    row_cap: int = DEFAULT_ROW_CAP,
) -> bool:
    status, _ = governed_reach(start, edges, hop_budget, row_cap)
    return status == "PRESENT"
