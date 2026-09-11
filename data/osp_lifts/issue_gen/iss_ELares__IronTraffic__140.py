"""Bundle validation: dangling refs, cycles, budgeted reach. Source: ELares/IronTraffic#140."""

from __future__ import annotations

from collections import deque

BUDGET_DEFAULT = 8


def resolve_refs(
    refs: list[tuple[str, str]],
    known: set[str],
) -> tuple[list[str], list[str]]:
    resolved: list[str] = []
    dangling: list[str] = []
    for src, dst in refs:
        if dst in known:
            resolved.append(f"{src}->{dst}")
        else:
            dangling.append(dst)
    return (sorted(set(resolved)), sorted(set(dangling)))


def detect_cycles(edges: list[tuple[str, str]]) -> list[str]:
    adj: dict[str, list[str]] = {}
    for a, b in edges:
        adj.setdefault(a, []).append(b)
        adj.setdefault(b, [])
    seen: set[str] = set()
    stack: set[str] = set()
    cycle: set[str] = set()

    def visit(node: str) -> None:
        if node in stack:
            cycle.add(node)
            return
        if node in seen:
            return
        seen.add(node)
        stack.add(node)
        for nxt in adj.get(node, []):
            visit(nxt)
            if nxt in cycle:
                cycle.add(node)
        stack.remove(node)

    for n in sorted(adj):
        visit(n)
    return sorted(cycle)


def budgeted_reach(
    start: str,
    edges: list[tuple[str, str]],
    budget: int = BUDGET_DEFAULT,
) -> list[str]:
    adj: dict[str, list[str]] = {}
    for a, b in edges:
        adj.setdefault(a, []).append(b)
        adj.setdefault(b, [])
    if start not in adj:
        return []
    reached: set[str] = set()
    q: deque[tuple[str, int]] = deque([(start, 0)])
    while q:
        node, depth = q.popleft()
        if node in reached:
            continue
        reached.add(node)
        if depth >= budget:
            continue
        for nxt in adj.get(node, []):
            if nxt not in reached:
                q.append((nxt, depth + 1))
    return sorted(reached)
