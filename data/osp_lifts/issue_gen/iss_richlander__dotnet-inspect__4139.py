"""richlander/dotnet-inspect#4139 — Member-centric call graph reachability."""

from __future__ import annotations

from collections import deque


class CallGraph:
    def __init__(self) -> None:
        self._members: set[str] = set()
        self._calls: dict[str, list[str]] = {}


def load_call_graph(
    members: list[str],
    edges: list[tuple[str, str]],
) -> CallGraph:
    cg = CallGraph()
    for mid in members:
        cg._members.add(mid)
        cg._calls.setdefault(mid, [])
    for caller, callee in edges:
        if caller in cg._members and callee in cg._members:
            cg._calls.setdefault(caller, []).append(callee)
    return cg


def reachable_members(graph: CallGraph, seed: str) -> list[str]:
    if seed not in graph._members:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([seed])
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in graph._calls.get(cur, []):
            if nxt not in seen:
                queue.append(nxt)
    return sorted(seen)


def callers_of(graph: CallGraph, member: str) -> list[str]:
    if member not in graph._members:
        return []
    out: list[str] = []
    for caller, callees in graph._calls.items():
        if member in callees:
            out.append(caller)
    return sorted(out)
