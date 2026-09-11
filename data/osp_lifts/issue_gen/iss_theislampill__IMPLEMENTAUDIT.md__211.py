"""theislampill/IMPLEMENTAUDIT.md#211 — nested L1-L5 control reach."""

from __future__ import annotations

from collections import deque


class ControlStore:
    def __init__(self) -> None:
        self.parent: dict[str, str | None] = {}
        self.children: dict[str, list[str]] = {}
        self.interrupts: dict[str, list[str]] = {}
        self.layers: set[str] = set()


def load_control(
    layers: list[tuple[str, str | None]],
    routes: list[tuple[str, str]],
) -> ControlStore:
    c = ControlStore()
    for layer, par in layers:
        c.layers.add(layer)
        c.parent[layer] = par
        c.children.setdefault(layer, [])
        c.interrupts.setdefault(layer, [])
        if par is not None:
            c.children.setdefault(par, []).append(layer)
    for src, dst in routes:
        if src in c.layers and dst in c.layers:
            c.interrupts[src].append(dst)
    return c


def active_layers(c: ControlStore, run_layer: str) -> list[str]:
    if run_layer not in c.layers:
        return []
    chain: list[str] = []
    cur: str | None = run_layer
    seen: set[str] = set()
    while cur is not None and cur not in seen:
        seen.add(cur)
        chain.append(cur)
        cur = c.parent.get(cur)
    return list(reversed(chain))


def convergence_targets(c: ControlStore, from_layer: str) -> list[str]:
    if from_layer not in c.layers:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([from_layer])
    out: set[str] = set()
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for tgt in sorted(c.interrupts.get(cur, [])):
            out.add(tgt)
            if tgt not in seen:
                q.append(tgt)
    return sorted(out)
