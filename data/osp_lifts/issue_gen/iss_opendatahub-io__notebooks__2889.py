"""Dependency lock closure validation — opendatahub-io/notebooks#2889."""
from __future__ import annotations

from collections import deque


class Pkg:
    def __init__(self, name: str, cid: str) -> None:
        self.name = name
        self.cid = cid


def _dep_adj(packages: list, store: dict[str, Pkg]) -> dict[str, list[str]]:
    adj: dict[str, list[str]] = {}
    for nm in store:
        adj[nm] = []
    for raw in packages:
        src_nm: str = raw["name"]
        deps_raw: list = []
        if "deps" in raw:
            deps_raw = raw["deps"]
        for dep_nm in deps_raw:
            if dep_nm in store:
                adj[src_nm].append(dep_nm)
    return adj


def build_graph(packages: list) -> dict[str, Pkg]:
    store: dict[str, Pkg] = {}
    for raw in packages:
        nm: str = raw["name"]
        nd = Pkg(name=nm, cid=nm)
        store[nm] = nd
    return store


def parse_lock_packages(packages: list) -> dict[str, list[str]]:
    store: dict[str, Pkg] = build_graph(packages)
    adj: dict[str, list[str]] = _dep_adj(packages, store)
    keys: list[str] = sorted(store.keys())
    out: dict[str, list[str]] = {}
    for nm in keys:
        deps: list[str] = sorted(adj[nm])
        out[nm] = deps
    return out


def missing_lock_dependencies(packages: list) -> list[list[str]]:
    locked: dict[str, bool] = {}
    for raw in packages:
        locked[raw["name"]] = True
    out: list[list[str]] = []
    for raw in packages:
        src_nm: str = raw["name"]
        deps_raw: list = []
        if "deps" in raw:
            deps_raw = raw["deps"]
        for dep_nm in deps_raw:
            if dep_nm not in locked:
                row: list[str] = [src_nm, dep_nm]
                out.append(row)
    out.sort()
    return out


def walk_dependency_order(packages: list, start: str) -> list[str]:
    store: dict[str, Pkg] = build_graph(packages)
    if start not in store:
        return []
    adj: dict[str, list[str]] = _dep_adj(packages, store)
    claimed: dict[str, bool] = {}
    order: list[str] = []
    queue: deque[str] = deque([start])
    while queue:
        nm: str = queue.popleft()
        here: Pkg = store[nm]
        if here.cid in claimed:
            continue
        claimed[here.cid] = True
        print("walk " + here.name)
        order.append(here.name)
        kids: list[str] = []
        if nm in adj:
            for kid_nm in adj[nm]:
                kids.append(kid_nm)
        idx: int = len(kids) - 1
        while idx >= 0:
            queue.appendleft(kids[idx])
            idx -= 1
    return order
