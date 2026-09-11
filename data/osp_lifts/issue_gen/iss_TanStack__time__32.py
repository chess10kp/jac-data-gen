"""TanStack/time#32 — FS/SS/FF/SF event dependency cascade with cycle guard."""

from collections import deque
from typing import Dict, List, Set, Tuple

DepType = str  # "FS" | "SS" | "FF" | "SF"
EventTimes = Tuple[int, int]  # (start, finish)


class DependencyError(ValueError):
    pass


class DependenciesModule:
    def __init__(self) -> None:
        self._events: Dict[str, EventTimes] = {}
        self._forward: Dict[str, List[Tuple[str, DepType]]] = {}
        self._backward: Dict[str, List[Tuple[str, DepType]]] = {}

    def register_event(self, event_id: str, start: int, finish: int) -> None:
        if finish < start:
            raise DependencyError("finish before start")
        self._events[event_id] = (start, finish)
        self._forward.setdefault(event_id, [])
        self._backward.setdefault(event_id, [])

    def createDependency(self, source_id: str, target_id: str, dep_type: DepType) -> None:
        if source_id not in self._events or target_id not in self._events:
            raise DependencyError("unknown event id")
        if dep_type not in ("FS", "SS", "FF", "SF"):
            raise DependencyError("invalid dependency type")
        if self._would_cycle(source_id, target_id):
            raise DependencyError(
                f"circular dependency: {source_id} -> {target_id} closes a cycle"
            )
        self._forward[source_id].append((target_id, dep_type))
        self._backward[target_id].append((source_id, dep_type))

    def move_event(self, event_id: str, new_start: int, new_finish: int) -> Dict[str, EventTimes]:
        if event_id not in self._events:
            raise DependencyError("unknown event id")
        if new_finish < new_start:
            raise DependencyError("finish before start")
        old = self._events[event_id]
        self._events[event_id] = (new_start, new_finish)
        delta_start = new_start - old[0]
        delta_finish = new_finish - old[1]
        order = self._topological_order()
        shifted: Dict[str, EventTimes] = {}
        for eid in order:
            if eid == event_id:
                shifted[eid] = (new_start, new_finish)
                continue
            start, finish = self._events[eid]
            for pred, dtype in self._backward[eid]:
                if pred not in self._events:
                    continue
                ps, pf = self._events[pred]
                req_start, req_finish = start, finish
                if dtype == "FS":
                    req_start = max(req_start, pf)
                    req_finish = max(req_finish, req_start + (finish - start))
                elif dtype == "SS":
                    req_start = max(req_start, ps)
                    req_finish = max(req_finish, req_start + (finish - start))
                elif dtype == "FF":
                    req_finish = max(req_finish, pf)
                    req_start = min(req_start, req_finish - (finish - start))
                elif dtype == "SF":
                    req_finish = max(req_finish, ps)
                    req_start = min(req_start, req_finish - (finish - start))
                start, finish = req_start, req_finish
            if (start, finish) != self._events[eid]:
                self._events[eid] = (start, finish)
                shifted[eid] = (start, finish)
        if delta_start or delta_finish:
            shifted.setdefault(event_id, (new_start, new_finish))
        return dict(sorted(shifted.items()))

    def validateEventDependencies(self, event_id: str) -> bool:
        if event_id not in self._events:
            raise DependencyError("unknown event id")
        start, finish = self._events[event_id]
        for pred, dtype in self._backward[event_id]:
            if pred not in self._events:
                return False
            ps, pf = self._events[pred]
            if dtype == "FS" and start < pf:
                return False
            if dtype == "SS" and start < ps:
                return False
            if dtype == "FF" and finish < pf:
                return False
            if dtype == "SF" and finish < ps:
                return False
        return True

    def _would_cycle(self, source_id: str, target_id: str) -> bool:
        # BFS from target along forward edges; cycle if source reachable
        seen: Set[str] = set()
        queue: deque[str] = deque([target_id])
        while queue:
            cur = queue.popleft()
            if cur == source_id:
                return True
            if cur in seen:
                continue
            seen.add(cur)
            for nxt, _ in self._forward.get(cur, []):
                if nxt not in seen:
                    queue.append(nxt)
        return False

    def _topological_order(self) -> List[str]:
        indeg: Dict[str, int] = {eid: 0 for eid in self._events}
        for src, outs in self._forward.items():
            for dst, _ in outs:
                if dst in indeg:
                    indeg[dst] += 1
        queue: deque[str] = deque(sorted(eid for eid, d in indeg.items() if d == 0))
        order: List[str] = []
        while queue:
            node = queue.popleft()
            order.append(node)
            for nxt, _ in sorted(self._forward.get(node, []), key=lambda x: x[0]):
                if nxt not in indeg:
                    continue
                indeg[nxt] -= 1
                if indeg[nxt] == 0:
                    queue.append(nxt)
        if len(order) != len(indeg):
            raise DependencyError("cycle detected in dependency graph")
        return order
