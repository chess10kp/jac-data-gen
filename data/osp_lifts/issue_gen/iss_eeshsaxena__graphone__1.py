"""eeshsaxena/graphone#1 — /graph endpoint recurses forever on investor cycles."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set, Tuple


class CompanyGraph:
  # Fresh handle per test; hand-rolled adjacency for portfolio edges.
    def __init__(self) -> None:
        self.companies: Dict[str, str] = {}
        self.invests: Dict[str, List[str]] = {}


def load_graph(
    companies: List[Tuple[str, str]],
    investments: List[Tuple[str, str]],
) -> CompanyGraph:
    g = CompanyGraph()
    for cid, name in companies:
        g.companies[cid] = name
        g.invests.setdefault(cid, [])
    for inv, tgt in investments:
        if inv in g.companies and tgt in g.companies:
            g.invests.setdefault(inv, []).append(tgt)
    return g


def graph_endpoint(g: CompanyGraph, company_id: str) -> List[str]:
  # Buggy production path: queue walk without cycle guard truncates or loops.
    if company_id not in g.companies:
        return []
    seen: Set[str] = set()
    q: deque[str] = deque([company_id])
    hits: List[str] = []
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        hits.append(cur)
        for nxt in sorted(g.invests.get(cur, [])):
            if nxt not in seen:
                q.append(nxt)
    return sorted(hits)


def has_investment_cycle(g: CompanyGraph, company_id: str) -> bool:
    if company_id not in g.companies:
        return False
    visiting: Set[str] = set()
    seen: Set[str] = set()

    def dfs(cid: str) -> bool:
        if cid in visiting:
            return True
        if cid in seen:
            return False
        visiting.add(cid)
        for nxt in g.invests.get(cid, []):
            if dfs(nxt):
                return True
        visiting.remove(cid)
        seen.add(cid)
        return False

    return dfs(company_id)


def investors_of(g: CompanyGraph, company_id: str) -> List[str]:
  # Reverse scan mimicking ORM N+1 lookups over the adjacency dict.
    if company_id not in g.companies:
        return []
    out: List[str] = []
    for inv, targets in g.invests.items():
        if company_id in targets:
            out.append(inv)
    return sorted(out)
