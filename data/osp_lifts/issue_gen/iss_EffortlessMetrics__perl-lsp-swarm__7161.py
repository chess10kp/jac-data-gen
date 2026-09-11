"""EffortlessMetrics/perl-lsp-swarm#7161 — bounded subpattern call reachability."""

from __future__ import annotations

from collections import deque


class PatternStore:
    def __init__(self) -> None:
        self._patterns: set[str] = set()
        self._calls: dict[str, list[str]] = {}


def load_patterns(
    patterns: list[str],
    calls: list[tuple[str, str]],
) -> PatternStore:
    ps = PatternStore()
    for pid in patterns:
        ps._patterns.add(pid)
        ps._calls.setdefault(pid, [])
    for src, dst in calls:
        if src in ps._patterns and dst in ps._patterns:
            ps._calls.setdefault(src, []).append(dst)
    return ps


def call_reachable(ps: PatternStore, start: str, depth_budget: int) -> list[str]:
    if start not in ps._patterns or depth_budget < 0:
        return []
    q: deque[tuple[str, int]] = deque([(start, 0)])
    claimed: set[str] = set()
    hits: list[str] = []
    while q:
        cur, depth = q.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        hits.append(cur)
        if depth >= depth_budget:
            continue
        for nxt in ps._calls.get(cur, []):
            if nxt not in claimed:
                q.append((nxt, depth + 1))
    return sorted(hits)


def budget_exhausted(ps: PatternStore, start: str, depth_budget: int) -> bool:
    reach = call_reachable(ps, start, depth_budget)
    full = call_reachable(ps, start, len(ps._patterns) + 5)
    return len(reach) < len(full)


def mutual_cycle_detected(ps: PatternStore, start: str) -> bool:
    seen: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> bool:
        if node in stack:
            return True
        if node in seen:
            return False
        seen.add(node)
        stack.add(node)
        for nxt in ps._calls.get(node, []):
            if dfs(nxt):
                return True
        stack.remove(node)
        return False

    return dfs(start)
