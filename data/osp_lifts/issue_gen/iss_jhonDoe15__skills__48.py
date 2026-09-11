"""jhonDoe15/skills#48 — Carve plan ticket frontier calculation."""

from __future__ import annotations


class PlanGraph:
    def __init__(self) -> None:
        self._tickets: set[str] = set()
        self._blockers: dict[str, list[str]] = {}
        self._done: set[str] = set()


def load_plan_graph(
    tickets: list[str],
    deps: list[tuple[str, str]],
    done: list[str],
) -> PlanGraph:
    g = PlanGraph()
    for tid in tickets:
        g._tickets.add(tid)
        g._blockers.setdefault(tid, [])
    for blocker, task in deps:
        if blocker in g._tickets and task in g._tickets:
            g._blockers.setdefault(task, []).append(blocker)
    g._done = set(done)
    return g


def frontier(g: PlanGraph) -> list[str]:
    ready: list[str] = []
    for tid in sorted(g._tickets):
        if tid in g._done:
            continue
        pending = [b for b in g._blockers.get(tid, []) if b not in g._done]
        if not pending:
            ready.append(tid)
    return ready


def detect_plan_cycles(g: PlanGraph) -> list[tuple[str, str]]:
    errors: list[tuple[str, str]] = []
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> None:
        visited.add(node)
        stack.add(node)
        for blk in g._blockers.get(node, []):
            if blk in stack:
                errors.append((blk, node))
            elif blk not in visited:
                dfs(blk)
        stack.remove(node)

    for tid in sorted(g._tickets):
        if tid not in visited:
            dfs(tid)
    return sorted(errors)


def mark_done(g: PlanGraph, ticket_id: str) -> None:
    if ticket_id in g._tickets:
        g._done.add(ticket_id)
