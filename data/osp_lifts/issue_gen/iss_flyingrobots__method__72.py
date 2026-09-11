"""flyingrobots/method#72 — GitHub issue dependency graph for Method."""

from __future__ import annotations

from collections import deque


class IssueGraph:
    # Hand-rolled adjacency for Depends-on / Blocks edges between issues.
    def __init__(self) -> None:
        self._issues: set[int] = set()
        self._depends: dict[int, list[int]] = {}
        self._open: set[int] = set()


def load_issue_graph(
    issue_ids: list[int],
    depends_edges: list[tuple[int, int]],
    open_issues: list[int] | None = None,
) -> IssueGraph:
    g = IssueGraph()
    for iid in issue_ids:
        g._issues.add(iid)
        g._depends.setdefault(iid, [])
    for blocker, blocked in depends_edges:
        if blocker in g._issues and blocked in g._issues:
            g._depends.setdefault(blocked, []).append(blocker)
            g._depends.setdefault(blocker, g._depends.get(blocker, []))
    if open_issues is None:
        g._open = set(issue_ids)
    else:
        g._open = {i for i in open_issues if i in g._issues}
    return g


def _unresolved_blockers(store: IssueGraph, issue: int) -> list[int]:
    blockers = store._depends.get(issue, [])
    return sorted(b for b in blockers if b in store._open)


def frontier_issues(store: IssueGraph) -> list[int]:
    # Open issues with no unresolved blockers.
    out: list[int] = []
    for iid in sorted(store._open):
        if not _unresolved_blockers(store, iid):
            out.append(iid)
    return out


def detect_dependency_cycles(store: IssueGraph) -> list[tuple[int, int]]:
    errors: list[tuple[int, int]] = []
    visited: set[int] = set()
    stack: set[int] = set()

    def dfs(node: int) -> None:
        visited.add(node)
        stack.add(node)
        for dep in store._depends.get(node, []):
            if dep in stack:
                errors.append((node, dep))
            elif dep not in visited:
                dfs(dep)
        stack.remove(node)

    for iid in sorted(store._issues):
        if iid not in visited:
            dfs(iid)
    return sorted(errors)


def critical_path_depth(store: IssueGraph, issue: int) -> int:
    if issue not in store._issues:
        return -1
    depth: dict[int, int] = {issue: 0}
    queue: deque[int] = deque([issue])
    best = 0
    while queue:
        cur = queue.popleft()
        for dep in store._depends.get(cur, []):
            nd = depth[cur] + 1
            if nd > best:
                best = nd
            if dep not in depth or nd > depth[dep]:
                depth[dep] = nd
                queue.append(dep)
    return best
