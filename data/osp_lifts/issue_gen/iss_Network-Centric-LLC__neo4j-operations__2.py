"""Network-Centric-LLC/neo4j-operations#2 — Epic issue dependency readiness."""

from __future__ import annotations


class IssueGraph:
    def __init__(self) -> None:
        self._issues: set[str] = set()
        self._blocked_by: dict[str, list[str]] = {}
        self._done: set[str] = set()


def load_issue_graph(
    issues: list[str],
    deps: list[tuple[str, str]],
    done: list[str],
) -> IssueGraph:
    g = IssueGraph()
    for iid in issues:
        g._issues.add(iid)
        g._blocked_by.setdefault(iid, [])
    for blocker, issue in deps:
        if blocker in g._issues and issue in g._issues:
            g._blocked_by.setdefault(issue, []).append(blocker)
    g._done = set(done)
    return g


def ready_issues(g: IssueGraph) -> list[str]:
    ready: list[str] = []
    for iid in sorted(g._issues):
        if iid in g._done:
            continue
        pending = [b for b in g._blocked_by.get(iid, []) if b not in g._done]
        if not pending:
            ready.append(iid)
    return ready


def blocked_closure(g: IssueGraph, issue_id: str) -> list[str]:
    if issue_id not in g._issues:
        return []
    seen: set[str] = {issue_id}
    stack = [issue_id]
    while stack:
        cur = stack.pop()
        for blk in g._blocked_by.get(cur, []):
            if blk not in seen:
                seen.add(blk)
                stack.append(blk)
    return sorted(seen)


def mark_resolved(g: IssueGraph, issue_id: str) -> None:
    if issue_id in g._issues:
        g._done.add(issue_id)
