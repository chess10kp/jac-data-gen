"""Bulk recursive service-entity deletes — open-metadata/OpenMetadata#29323.

Before-code: id-keyed parent pointers + children adjacency lists; delete
closure collected by an explicit stack walk, then entities are removed in
a second sweep (perf pain from N+1 per-child DB round-trips in production).
"""

from __future__ import annotations

from typing import Dict, List, Optional, Set


class MetadataStore:
    def __init__(self) -> None:
        self._labels: Dict[str, str] = {}
        self._parent: Dict[str, Optional[str]] = {}
        self._children: Dict[str, List[str]] = {}

    def register_entity(self, eid: str, kind: str = "") -> None:
        if eid in self._labels:
            return
        self._labels[eid] = kind
        self._parent[eid] = None
        self._children[eid] = []

    def link_child(self, parent_id: str, child_id: str) -> None:
        if parent_id not in self._labels or child_id not in self._labels:
            return
        self._parent[child_id] = parent_id
        self._children[parent_id].append(child_id)

    def collect_delete_closure(self, root_id: str) -> List[str]:
        if root_id not in self._labels:
            return []
        seen: Set[str] = set()
        stack: List[str] = [root_id]
        out: List[str] = []
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            out.append(cur)
            for ch in self._children.get(cur, []):
                if ch not in seen:
                    stack.append(ch)
        return out

    def bulk_delete(self, root_id: str) -> List[str]:
        targets = self.collect_delete_closure(root_id)
        for eid in targets:
            self._labels.pop(eid, None)
            self._parent.pop(eid, None)
            self._children.pop(eid, None)
        for pid, kids in list(self._children.items()):
            self._children[pid] = [k for k in kids if k in self._labels]
        return sorted(targets)

    def exists(self, eid: str) -> bool:
        return eid in self._labels

    def children_of(self, eid: str) -> List[str]:
        if eid not in self._labels:
            return []
        return sorted(self._children.get(eid, []))


def build_store() -> MetadataStore:
    return MetadataStore()
