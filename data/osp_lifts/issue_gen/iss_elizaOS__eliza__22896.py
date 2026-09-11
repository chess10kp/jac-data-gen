"""elizaOS/eliza#22896 — resettable synthetic-world test platform."""

from __future__ import annotations

from typing import Dict, List, Set, Tuple


class WorldPlatform:
    def __init__(self) -> None:
        self._kinds: Dict[str, str] = {}
        self._parent: Dict[str, str | None] = {}
        self._children: Dict[str, List[str]] = {}
        self._active: Dict[str, bool] = {}


def load_world(
    entities: List[Tuple[str, str]],
    contains: List[Tuple[str, str]],
) -> WorldPlatform:
    world = WorldPlatform()
    for eid, kind in entities:
        world._kinds[eid] = kind
        world._parent[eid] = None
        world._children.setdefault(eid, [])
        world._active[eid] = True
    for parent, child in contains:
        if parent not in world._kinds or child not in world._kinds:
            continue
        world._parent[child] = parent
        if child not in world._children[parent]:
            world._children[parent].append(child)
    return world


def _subtree(world: WorldPlatform, root: str) -> List[str]:
    if root not in world._kinds:
        return []
    seen: Set[str] = set()
    out: List[str] = []
    stack = [root]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for ch in sorted(world._children.get(cur, [])):
            if ch not in seen:
                stack.append(ch)
    return out


def reset_entity(world: WorldPlatform, entity_id: str) -> List[str]:
    if entity_id not in world._kinds:
        return []
    targets = _subtree(world, entity_id)
    deactivated: List[str] = []
    for eid in targets:
        if world._active.get(eid, False):
            world._active[eid] = False
            deactivated.append(eid)
    return sorted(deactivated)


def active_entities(world: WorldPlatform) -> List[str]:
    return sorted(eid for eid, on in world._active.items() if on)
