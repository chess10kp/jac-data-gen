"""Recursive Git submodule install ordering. Source: zed-pkg/zed-cli#177."""

from __future__ import annotations

from collections import deque


def submodule_closure(root: str, children: dict[str, list[str]]) -> list[str]:
    # Recursive submodule walk via children adjacency + queue (recursive-CTE shape).
    settled: set[str] = set()
    order: list[str] = []
    work: deque[str] = deque([root])
    while work:
        node = work.popleft()
        if node in settled:
            continue
        settled.add(node)
        order.append(node)
        for child in children.get(node, []):
            if child not in settled:
                work.append(child)
    return order


def submodule_order(paths: list[str], parent: dict[str, str]) -> list[str]:
    # Topological install order: parent submodules before nested children.
    nodes: set[str] = set(paths)
    for child, par in parent.items():
        nodes.add(child)
        nodes.add(par)
    children: dict[str, list[str]] = {}
    indeg: dict[str, int] = {n: 0 for n in nodes}
    for child, par in parent.items():
        children.setdefault(par, []).append(child)
        indeg[child] = indeg.get(child, 0) + 1
        indeg.setdefault(par, 0)
    ready: deque[str] = deque(sorted([n for n, d in indeg.items() if d == 0]))
    topo: list[str] = []
    while ready:
        node = ready.popleft()
        topo.append(node)
        for ch in sorted(children.get(node, [])):
            indeg[ch] -= 1
            if indeg[ch] == 0:
                ready.append(ch)
    if len(topo) != len(nodes):
        raise ValueError("recursive submodule cycle")
    want = set(paths)
    return [p for p in topo if p in want]


def submodule_cycle_safe(parent_map: dict[str, str]) -> bool:
    # Cycle probe on parent pointers (recursive submodule hazard).
    for start in parent_map:
        seen: set[str] = set()
        cur = start
        while cur in parent_map:
            if cur in seen:
                return False
            seen.add(cur)
            cur = parent_map[cur]
    return True
