"""pytorch/pytorch#193703 — TTIR shared-subgraph access reach with cycle guard."""

from __future__ import annotations

from collections import defaultdict


class IrGraph:
    def __init__(self) -> None:
        self._nodes: set[int] = set()
        self._ops: dict[int, list[int]] = defaultdict(list)


def load_ir_graph(edges: list[tuple[int, int]]) -> IrGraph:
    g = IrGraph()
    for src, dst in edges:
        g._nodes.update([src, dst])
        g._ops[src].append(dst)
    return g


def access_reach(g: IrGraph, start: int) -> list[int]:
    if start not in g._nodes:
        return []
    seen: set[int] = set()
    stack = [start]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in g._ops.get(cur, []):
            if nxt not in seen:
                stack.append(nxt)
    return sorted(seen)


def param_touch_count(g: IrGraph, start: int, param_idx: int) -> int:
    if start not in g._nodes:
        return 0
    count = 0
    seen: set[int] = set()
    stack = [start]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        if cur == param_idx:
            count += 1
        for nxt in g._ops.get(cur, []):
            stack.append(nxt)
    return min(count, 2)
