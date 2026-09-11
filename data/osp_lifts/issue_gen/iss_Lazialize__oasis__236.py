"""Lazialize/oasis#236 — Recursive OpenAPI callback operation lint walk.

Hand-rolled adjacency dict + queue walk with identity cycle guards so nested
callback subtrees receive the same lint coverage as root path operations.
"""

from __future__ import annotations

from collections import deque


class OpenApiDoc:
    def __init__(self) -> None:
        self.operations: set[str] = set()
        self.callbacks: dict[str, list[str]] = {}
        self.refs: dict[str, str] = {}


def load_openapi_doc(
    operations: list[str],
    callbacks: list[tuple[str, str]],
    refs: list[tuple[str, str]],
) -> OpenApiDoc:
    g = OpenApiDoc()
    for op in operations:
        g.operations.add(op)
        g.callbacks.setdefault(op, [])
    for owner, cb in callbacks:
        if owner in g.operations and cb in g.operations:
            g.callbacks[owner].append(cb)
    for src, dst in refs:
        if src in g.operations and dst in g.operations:
            g.refs[src] = dst
    return g


def _resolve(g: OpenApiDoc, op_id: str, visiting: set[str]) -> str:
    cur = op_id
    while cur in g.refs:
        if cur in visiting:
            break
        visiting.add(cur)
        cur = g.refs[cur]
    return cur


def lint_reachable(g: OpenApiDoc, root: str) -> list[str]:
    if root not in g.operations:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([root])
    while q:
        cur = q.popleft()
        resolved = _resolve(g, cur, set())
        if resolved in seen:
            continue
        seen.add(resolved)
        for cb in g.callbacks.get(resolved, []):
            if cb not in seen:
                q.append(cb)
    return sorted(seen)
