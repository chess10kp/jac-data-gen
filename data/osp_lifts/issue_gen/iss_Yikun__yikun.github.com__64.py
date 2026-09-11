"""Yikun/yikun.github.com#64 — nested resource provider adjacency and NUMA-aware capacity."""

from collections import deque
from typing import Dict, List, Optional, Set, Tuple

ProviderId = str
ResourceClass = str


class PlacementError(ValueError):
    pass


class NestedResourceTree:
    def __init__(self) -> None:
        self._parent: Dict[ProviderId, Optional[ProviderId]] = {}
        self._children: Dict[ProviderId, List[ProviderId]] = {}
        self._inventory: Dict[ProviderId, Dict[ResourceClass, int]] = {}
        self._allocation: Dict[ProviderId, Dict[ResourceClass, int]] = {}

    def add_provider(self, provider_id: ProviderId, parent_id: Optional[ProviderId] = None) -> None:
        if provider_id in self._parent:
            raise PlacementError("duplicate provider")
        if parent_id is not None and parent_id not in self._parent:
            raise PlacementError("unknown parent")
        self._parent[provider_id] = parent_id
        self._children.setdefault(provider_id, [])
        self._inventory[provider_id] = {}
        self._allocation[provider_id] = {}
        if parent_id is not None:
            self._children.setdefault(parent_id, []).append(provider_id)

    def set_inventory(self, provider_id: ProviderId, rc: ResourceClass, total: int) -> None:
        if provider_id not in self._parent:
            raise PlacementError("unknown provider")
        self._inventory[provider_id][rc] = total
        self._allocation[provider_id].setdefault(rc, 0)

    def allocate(self, provider_id: ProviderId, rc: ResourceClass, amount: int) -> None:
        if provider_id not in self._parent:
            raise PlacementError("unknown provider")
        used = self._allocation[provider_id].get(rc, 0) + amount
        cap = self._inventory[provider_id].get(rc, 0)
        if used > cap:
            raise PlacementError("local capacity exceeded")
        self._allocation[provider_id][rc] = used

    def descendants(self, root: ProviderId) -> List[ProviderId]:
        if root not in self._parent:
            raise PlacementError("unknown provider")
        seen: Set[ProviderId] = set()
        queue: deque[ProviderId] = deque([root])
        out: List[ProviderId] = []
        while queue:
            cur = queue.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            out.append(cur)
            for child in sorted(self._children.get(cur, [])):
                queue.append(child)
        return out

    def aggregated_free(self, root: ProviderId, rc: ResourceClass) -> int:
        total = 0
        for pid in self.descendants(root):
            cap = self._inventory[pid].get(rc, 0)
            used = self._allocation[pid].get(rc, 0)
            total += max(cap - used, 0)
        return total

    def can_place(self, root: ProviderId, rc: ResourceClass, amount: int, numa_aware: bool) -> bool:
        if numa_aware:
            for pid in self.descendants(root):
                free = self._inventory[pid].get(rc, 0) - self._allocation[pid].get(rc, 0)
                if free >= amount:
                    return True
            return False
        return self.aggregated_free(root, rc) >= amount

    def ancestor_chain(self, provider_id: ProviderId) -> List[ProviderId]:
        if provider_id not in self._parent:
            raise PlacementError("unknown provider")
        chain: List[ProviderId] = []
        cur: Optional[ProviderId] = provider_id
        while cur is not None:
            chain.append(cur)
            cur = self._parent.get(cur)
        return list(reversed(chain))
