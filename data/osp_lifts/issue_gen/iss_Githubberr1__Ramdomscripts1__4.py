"""Githubberr1/Ramdomscripts1#4 -- SQL recursive CTE employee hierarchy."""

from __future__ import annotations

from collections import deque

class Org:
    def __init__(self) -> None:
        self.employees: set[str] = set()
        self.manager: dict[str, str | None] = {}
        self.children: dict[str, list[str]] = {}

def make_org() -> Org:
    return Org()

def add_employee(org: Org, emp: str, manager: str | None) -> None:
    if emp in org.employees:
        raise ValueError("duplicate employee")
    org.employees.add(emp)
    org.manager[emp] = manager
    org.children.setdefault(emp, [])
    if manager is not None:
        if manager not in org.employees and manager != emp:
            # allow forward ref: create placeholder
            org.employees.add(manager)
            org.manager.setdefault(manager, None)
            org.children.setdefault(manager, [])
        org.children.setdefault(manager, []).append(emp)

def all_reports(org: Org, manager: str) -> list[tuple[str, int]]:
    if manager not in org.employees:
        return []
    out: list[tuple[str, int]] = []
    # BFS with depth (hand-rolled queue walk)
    q: deque[tuple[str, int]] = deque()
    seen: set[str] = set([manager])
    for child in org.children.get(manager, []):
        q.append((child, 1))
    while q:
        cur, lvl = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        out.append((cur, lvl))
        for nxt in org.children.get(cur, []):
            if nxt not in seen:
                q.append((nxt, lvl + 1))
    return sorted(out)

def chain_to_root(org: Org, emp: str) -> list[str]:
    chain: list[str] = []
    cur: str | None = emp
    seen: set[str] = set()
    while cur and cur not in seen:
        chain.append(cur)
        seen.add(cur)
        cur = org.manager.get(cur)
    return chain

def has_cycle(org: Org) -> bool:
    # DFS cycle detection via recursion stack
    visited: set[str] = set()
    stack: set[str] = set()
    def dfs(node: str) -> bool:
        visited.add(node)
        stack.add(node)
        for ch in org.children.get(node, []):
            if ch not in visited:
                if dfs(ch):
                    return True
            elif ch in stack:
                return True
        stack.remove(node)
        return False
    for n in list(org.employees):
        if n not in visited:
            if dfs(n):
                return True
    return False

def top_customers_mock(orders: list[dict], days: int = 365) -> list[tuple[str, float]]:
    totals: dict[str, float] = {}
    for o in orders:
        totals[o["customer_id"]] = totals.get(o["customer_id"], 0) + o["total_amount"]
    ranked = sorted(totals.items(), key=lambda x: -x[1])
    return ranked[:5]
