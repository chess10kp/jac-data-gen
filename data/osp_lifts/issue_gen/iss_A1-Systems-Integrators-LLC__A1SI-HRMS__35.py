"""Unlimited-depth org chart inspired by A1-Systems-Integrators-LLC/A1SI-HRMS#35."""

from collections import deque


class OrgStore:
    def __init__(self) -> None:
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}

    def add_employee(self, emp_id: str, manager_id: str | None = None) -> None:
        if emp_id in self._parent:
            raise ValueError(f"duplicate employee: {emp_id}")
        if manager_id is not None and manager_id not in self._parent:
            raise KeyError(manager_id)
        self._parent[emp_id] = manager_id
        self._children.setdefault(emp_id, [])
        if manager_id is not None:
            self._children.setdefault(manager_id, []).append(emp_id)

    def ancestors(self, emp_id: str) -> list[str]:
        if emp_id not in self._parent:
            raise KeyError(emp_id)
        out: list[str] = []
        cur = self._parent.get(emp_id)
        seen: set[str] = set()
        while cur is not None:
            if cur in seen:
                break
            seen.add(cur)
            out.append(cur)
            cur = self._parent.get(cur)
        return out

    def descendants(self, emp_id: str) -> list[str]:
        if emp_id not in self._parent:
            raise KeyError(emp_id)
        order: list[str] = []
        q: deque[str] = deque(self._children.get(emp_id, []))
        claimed: set[str] = set()
        while q:
            n = q.popleft()
            if n in claimed:
                continue
            claimed.add(n)
            order.append(n)
            for c in self._children.get(n, []):
                if c not in claimed:
                    q.append(c)
        return sorted(order)

    def would_cycle(self, manager_id: str, emp_id: str) -> bool:
        if manager_id not in self._parent or emp_id not in self._parent:
            raise KeyError(manager_id if manager_id not in self._parent else emp_id)
        return emp_id in self.ancestors(manager_id) or manager_id == emp_id
