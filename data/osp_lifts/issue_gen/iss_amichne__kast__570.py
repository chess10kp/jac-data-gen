"""amichne/kast#570 — public tooling delivery issue dependency graph."""

from __future__ import annotations

from collections import deque


class CycleError(Exception):
    pass


class IssueGraph:
    def __init__(self) -> None:
        self._issues: set[str] = set()
        self._blocked_by: dict[str, list[str]] = {}
        self._parent_of: dict[str, str | None] = {}


def load_issue_graph(
    issue_ids: list[str],
    blocked_edges: list[tuple[str, str]],
    parent_links: list[tuple[str, str | None]],
) -> IssueGraph:
    g = IssueGraph()
    for iid in issue_ids:
        g._issues.add(iid)
        g._blocked_by.setdefault(iid, [])
    for blocker, blocked in blocked_edges:
        if blocker in g._issues and blocked in g._issues:
            g._blocked_by.setdefault(blocked, []).append(blocker)
    for iid, parent in parent_links:
        if iid in g._issues:
            g._parent_of[iid] = parent
    return g


def dependency_levels(g: IssueGraph) -> list[list[str]]:
    indegree: dict[str, int] = {n: 0 for n in g._issues}
    rev: dict[str, list[str]] = {n: [] for n in g._issues}
    for blocked, blockers in g._blocked_by.items():
        for b in blockers:
            indegree[blocked] += 1
            rev[b].append(blocked)
    layers: list[list[str]] = []
    visited: set[str] = set()
    ready = {n for n, d in indegree.items() if d == 0}
    while ready:
        layer = sorted(ready)
        layers.append(layer)
        next_ready: set[str] = set()
        for node in layer:
            visited.add(node)
            for other in rev.get(node, []):
                indegree[other] -= 1
                if indegree[other] == 0 and other not in visited:
                    next_ready.add(other)
        ready = next_ready
    if len(visited) != len(g._issues):
        raise CycleError("blocked-by cycle")
    return layers


def ready_frontier(g: IssueGraph, completed: list[str]) -> list[str]:
    done = set(completed)
    layers = dependency_levels(g)
    for layer in layers:
        frontier = [i for i in layer if i not in done]
        if frontier:
            return sorted(frontier)
    return []


def child_issues(g: IssueGraph, parent: str) -> list[str]:
    out: list[str] = []
    for iid, par in g._parent_of.items():
        if par == parent:
            out.append(iid)
    return sorted(out)


def unblock_reach(g: IssueGraph, root: str) -> list[str]:
    if root not in g._issues:
        return []
    rev: dict[str, list[str]] = {n: [] for n in g._issues}
    for blocked, blockers in g._blocked_by.items():
        for b in blockers:
            rev[b].append(blocked)
    seen: set[str] = set()
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for nxt in rev.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)
