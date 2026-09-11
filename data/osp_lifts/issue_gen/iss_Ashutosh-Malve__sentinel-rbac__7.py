"""Ashutosh-Malve/sentinel-rbac#7 — org parent chain for materialized-path lookup."""

from __future__ import annotations


class OrgRegistry:
    def __init__(self) -> None:
        self._parent_of: dict[str, str | None] = {}


def load_org_registry(orgs: list[tuple[str, str | None]]) -> OrgRegistry:
    reg = OrgRegistry()
    for oid, parent in orgs:
        if parent is not None and parent not in reg._parent_of:
            raise KeyError("unknown parent organization")
        reg._parent_of[oid] = parent
    return reg


def _walk_up(reg: OrgRegistry, org_id: str) -> list[str]:
    if org_id not in reg._parent_of:
        return []
    chain: list[str] = []
    cur: str | None = org_id
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        cur = reg._parent_of.get(cur)
    rev: list[str] = []
    for i in range(len(chain) - 1, -1, -1):
        rev.append(chain[i])
    return rev


def ancestor_path(reg: OrgRegistry, org_id: str) -> list[str]:
    return _walk_up(reg, org_id)


def materialized_path(reg: OrgRegistry, org_id: str) -> str:
    parts = _walk_up(reg, org_id)
    if not parts:
        return ""
    return "/" + "/".join(parts)


def org_depth(reg: OrgRegistry, org_id: str) -> int:
    path = _walk_up(reg, org_id)
    return max(len(path) - 1, 0)
