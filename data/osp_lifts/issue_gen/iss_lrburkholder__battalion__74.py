"""lrburkholder/battalion#74 — BTN-98 Cartography logical data contract."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set, Tuple


class Cartography:
    def __init__(self) -> None:
        self._fields: Set[str] = set()
        self._derives: Dict[str, List[str]] = {}

    def add_field(self, name: str) -> None:
        self._fields.add(name)
        self._derives.setdefault(name, [])

    def derive(self, child: str, parent: str) -> None:
        if child not in self._fields or parent not in self._fields:
            raise KeyError("unknown field")
        if parent not in self._derives[child]:
            self._derives[child].append(parent)

    def lineage_closure(self, field: str) -> List[str]:
        if field not in self._fields:
            return []
        seen: Set[str] = set()
        work: deque[str] = deque([field])
        while work:
            cur = work.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            for parent in sorted(self._derives.get(cur, [])):
                if parent not in seen:
                    work.append(parent)
        seen.discard(field)
        return sorted(seen)

    def canonical_fields(self) -> List[str] | None:
        indeg = {f: len(self._derives.get(f, [])) for f in self._fields}
        out: List[str] = []
        ready = sorted([f for f, d in indeg.items() if d == 0])
        while ready:
            out.extend(ready)
            nxt: List[str] = []
            for base in ready:
                for child in self._fields:
                    if base in self._derives.get(child, []):
                        indeg[child] -= 1
                        if indeg[child] == 0:
                            nxt.append(child)
            ready = sorted(nxt)
        return out if len(out) == len(self._fields) else None


def load_cartography(
    fields: List[str],
    derives: List[Tuple[str, str]],
) -> Cartography:
    c = Cartography()
    for name in fields:
        c.add_field(name)
    for child, parent in derives:
        c.derive(child, parent)
    return c


def lineage_closure(c: Cartography, field: str) -> List[str]:
    return c.lineage_closure(field)


def canonical_fields(c: Cartography) -> List[str] | None:
    return c.canonical_fields()
