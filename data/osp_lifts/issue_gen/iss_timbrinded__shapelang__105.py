"""timbrinded/shapelang#105 — transitive reviewed effect reachability for complete summaries."""

from __future__ import annotations

from collections import deque


class EffectGraph:
    def __init__(self) -> None:
        self._funcs: set[str] = set()
        self._invokes: dict[str, list[str]] = {}
        self._effects: dict[str, set[str]] = {}
        self._unknown: set[str] = set()


def load_effect_graph(
    funcs: list[str],
    invokes: list[tuple[str, str]],
    effects: list[tuple[str, str]],
    unknown: list[str] | None = None,
) -> EffectGraph:
    g = EffectGraph()
    for fn in funcs:
        g._funcs.add(fn)
        g._invokes.setdefault(fn, [])
        g._effects.setdefault(fn, set())
    for src, dst in invokes:
        if src in g._funcs and dst in g._funcs:
            g._invokes.setdefault(src, []).append(dst)
    for fn, eff in effects:
        if fn in g._funcs:
            g._effects.setdefault(fn, set()).add(eff)
    g._unknown = set(unknown or [])
    return g


def _reachable_funcs(g: EffectGraph, start: str) -> set[str]:
    if start not in g._funcs:
        return set()
    q: deque[str] = deque([start])
    seen: set[str] = set()
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in g._invokes.get(cur, []):
            if nxt not in seen:
                q.append(nxt)
    return seen


def reachable_effects(g: EffectGraph, func_id: str) -> list[str]:
    scope = _reachable_funcs(g, func_id)
    if func_id in g._unknown:
        return []
    out: set[str] = set()
    for fn in scope:
        if fn in g._unknown:
            return []
        out.update(g._effects.get(fn, set()))
    return sorted(out)


def missing_effects(g: EffectGraph, func_id: str, declared: list[str]) -> list[str]:
    need = set(reachable_effects(g, func_id))
    have = set(declared)
    return sorted(need - have)


def has_unknown_reachable(g: EffectGraph, func_id: str) -> bool:
    for fn in _reachable_funcs(g, func_id):
        if fn in g._unknown:
            return True
    return False
