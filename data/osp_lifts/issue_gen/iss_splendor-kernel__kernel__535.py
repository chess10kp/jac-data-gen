"""splendor-kernel/kernel#535 — Change impact blast-radius dependent traversal.

Hand-rolled adjacency dict + queue walk collecting transitive dependents for
CHG-003 impact reports with cycle-safe once-only visitation.
"""

from __future__ import annotations

from collections import deque


class ChangeGraph:
    def __init__(self) -> None:
        self.subjects: set[str] = set()
        self.depends: dict[str, list[str]] = {}


def load_change_graph(
    subjects: list[str],
    edges: list[tuple[str, str]],
) -> ChangeGraph:
    g = ChangeGraph()
    for sid in subjects:
        g.subjects.add(sid)
        g.depends.setdefault(sid, [])
    for src, dst in edges:
        if src in g.subjects and dst in g.subjects:
            g.depends[src].append(dst)
    return g


def direct_dependents(g: ChangeGraph, subject: str) -> list[str]:
    if subject not in g.subjects:
        return []
    return sorted(g.depends.get(subject, []))


def blast_radius(g: ChangeGraph, subject: str) -> list[str]:
    if subject not in g.subjects:
        return []
    seen: set[str] = {subject}
    q: deque[str] = deque([subject])
    while q:
        cur = q.popleft()
        for nxt in g.depends.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                q.append(nxt)
    return sorted(seen)
