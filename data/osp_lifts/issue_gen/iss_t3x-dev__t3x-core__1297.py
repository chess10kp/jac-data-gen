"""t3x-dev/t3x-core#1297 — Preserve mixed history and remove the retired Chat stack."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set, Tuple


class HistoryGraph:
    def __init__(self) -> None:
        self._modules: Dict[str, str] = {}
        self._children: Dict[str, List[str]] = {}
        self._deps: Dict[str, List[str]] = {}
        self._rev_dep: Dict[str, List[str]] = {}
        self._retired: Dict[str, bool] = {}
        self._active: Dict[str, bool] = {}
        self._events: List[Tuple[str, str]] = []


def load_history(
    modules: List[Tuple[str, str]],
    contains: List[Tuple[str, str]],
    depends: List[Tuple[str, str]],
    events: List[Tuple[str, str]],
) -> HistoryGraph:
    g = HistoryGraph()
    for mid, stack in modules:
        g._modules[mid] = stack
        g._children.setdefault(mid, [])
        g._deps.setdefault(mid, [])
        g._rev_dep.setdefault(mid, [])
        g._retired[mid] = False
        g._active[mid] = True
    for parent, child in contains:
        if parent in g._modules and child in g._modules:
            g._children.setdefault(parent, []).append(child)
    for consumer, provider in depends:
        if consumer in g._modules and provider in g._modules:
            g._deps[consumer].append(provider)
            g._rev_dep[provider].append(consumer)
    g._events = list(events)
    return g


def _stack_subtree(g: HistoryGraph, root: str) -> List[str]:
    if root not in g._modules:
        return []
    seen: Set[str] = set()
    stack = [root]
    out: List[str] = []
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for ch in sorted(g._children.get(cur, [])):
            if ch not in seen:
                stack.append(ch)
    return out


def mark_retired(g: HistoryGraph, stack_root: str) -> List[str]:
    marked: List[str] = []
    for mid in _stack_subtree(g, stack_root):
        if not g._retired.get(mid, False):
            g._retired[mid] = True
            marked.append(mid)
    return sorted(marked)


def _dependent_closure(g: HistoryGraph, seeds: List[str]) -> List[str]:
    seen: Set[str] = set()
    q: deque[str] = deque()
    for sid in seeds:
        q.append(sid)
    while q:
        prov = q.popleft()
        for consumer in sorted(g._rev_dep.get(prov, [])):
            if consumer not in g._modules:
                continue
            if not g._active.get(consumer, False):
                continue
            if consumer in seen:
                continue
            seen.add(consumer)
            q.append(consumer)
    return sorted(seen)


def purge_retired(g: HistoryGraph) -> List[str]:
    seeds = sorted(mid for mid, on in g._retired.items() if on)
    if not seeds:
        return []
    victims = _dependent_closure(g, seeds)
    deactivated: List[str] = []
    for mid in victims:
        if g._active.get(mid, False):
            g._active[mid] = False
            deactivated.append(mid)
    return deactivated


def active_modules(g: HistoryGraph) -> List[str]:
    return sorted(
        mid
        for mid in g._modules
        if g._active.get(mid, False) and not g._retired.get(mid, False)
    )
