"""snissn/music#1 — SongDNA issue dependency graph for execution scheduling.

Hand-rolled parent pointers and child adjacency tracking which production
issues block downstream renderer, DAW, and delivery integration gates.
"""

from __future__ import annotations


class IssueGraph:
    def __init__(self) -> None:
        self.issues: set[str] = set()
        self.blocked_by: dict[str, list[str]] = {}


def load_issue_graph(
    issues: list[str],
    blocks: list[tuple[str, str]],
) -> IssueGraph:
    g = IssueGraph()
    for iid in issues:
        g.issues.add(iid)
        g.blocked_by.setdefault(iid, [])
    for blocker, blocked in blocks:
        if blocker in g.issues and blocked in g.issues:
            g.blocked_by.setdefault(blocked, []).append(blocker)
    return g


def _upstream_ids(g: IssueGraph, iid: str) -> set[str]:
    seen: set[str] = set()
    stack: list[str] = [iid]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for blk in sorted(g.blocked_by.get(cur, [])):
            stack.append(blk)
    return seen


def critical_path(g: IssueGraph, target: str) -> list[str]:
    if target not in g.issues:
        return []
    return sorted(_upstream_ids(g, target))


def unblocked(g: IssueGraph, done: list[str]) -> list[str]:
    finished = set(done)
    ready: list[str] = []
    for iid in sorted(g.issues):
        if iid in finished:
            continue
        blockers = [b for b in critical_path(g, iid) if b != iid]
        if all(b in finished for b in blockers):
            ready.append(iid)
    return ready
