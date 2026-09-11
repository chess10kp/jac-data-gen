"""Scene draw-order cache — pygfx/pygfx#1298."""
from __future__ import annotations
from typing import Dict, List, Set

class SceneCache:
    def __init__(self) -> None:
        self._children: Dict[str, List[str]] = {}
        self._dirty: Set[str] = set()
        self._nodes: Set[str] = set()

    def register(self, nid: str, parent: str | None = None) -> None:
        self._nodes.add(nid)
        self._children.setdefault(nid, [])
        if parent is not None:
            self._children.setdefault(parent, []).append(nid)

    def invalidate(self, nid: str) -> None:
        if nid not in self._nodes:
            return
        stack = [nid]
        while stack:
            cur = stack.pop()
            if cur in self._dirty:
                continue
            self._dirty.add(cur)
            stack.extend(self._children.get(cur, []))

    def draw_order(self, root_id: str) -> List[str]:
        if root_id not in self._nodes:
            return []
        out: List[str] = []
        stack = [root_id]
        seen: Set[str] = set()
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            out.append(cur)
            for ch in reversed(sorted(self._children.get(cur, []))):
                stack.append(ch)
        return out

def build_scene_cache() -> SceneCache:
    return SceneCache()
