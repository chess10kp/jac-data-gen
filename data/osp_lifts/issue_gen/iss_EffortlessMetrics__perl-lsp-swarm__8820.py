"""EffortlessMetrics/perl-lsp-swarm#8820 — reverse invalidation closure from compiler world."""

from __future__ import annotations

from collections import deque


class CompilerWorld:
    def __init__(self) -> None:
        self._modules: set[str] = set()
        self._depends: dict[str, list[str]] = {}
        self._reverse: dict[str, list[str]] = {}


def load_world(
    modules: list[str],
    depends: list[tuple[str, str]],
) -> CompilerWorld:
    world = CompilerWorld()
    for name in modules:
        world._modules.add(name)
        world._depends.setdefault(name, [])
        world._reverse.setdefault(name, [])
    for src, dst in depends:
        if src in world._modules and dst in world._modules:
            world._depends.setdefault(src, []).append(dst)
            world._reverse.setdefault(dst, []).append(src)
    return world


def reverse_invalidation_closure(world: CompilerWorld, changed: str) -> list[str]:
    if changed not in world._modules:
        return []
    seen: set[str] = set()
    order: list[str] = []
    q: deque[str] = deque([changed])
    while q:
        mod = q.popleft()
        if mod in seen:
            continue
        seen.add(mod)
        order.append(mod)
        for dep in sorted(world._reverse.get(mod, [])):
            if dep not in seen:
                q.append(dep)
    return order


def classify_transition(old_iface: set[str], new_iface: set[str]) -> str:
    if old_iface == new_iface:
        return "no_change"
    if old_iface.issubset(new_iface) or new_iface.issubset(old_iface):
        return "public_change"
    return "unknown"


def invalidate_for_transition(
    world: CompilerWorld,
    changed: str,
    transition: str,
) -> list[str]:
    if transition == "no_change":
        return [changed] if changed in world._modules else []
    return reverse_invalidation_closure(world, changed)
