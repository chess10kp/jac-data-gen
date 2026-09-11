"""lightcloud00/herphase-pages#12 — canonical CycleKeep site routes and legacy redirect resolution."""

from __future__ import annotations

from collections import deque

ROLE_CANONICAL = "canonical"
ROLE_MIRROR = "mirror"
ROLE_LEGACY = "legacy"


class SiteHost:
    def __init__(self, hid: str, role: str, indexed: bool) -> None:
        self.hid = hid
        self.role = role
        self.indexed = indexed


class SiteRoute:
    def __init__(self, rid: str, hid: str, path: str, status: int = 200) -> None:
        self.rid = rid
        self.hid = hid
        self.path = path
        self.status = status


class SiteGraph:
    def __init__(self) -> None:
        self.hosts: dict[str, SiteHost] = {}
        self.routes: dict[str, SiteRoute] = {}
        self.redirects: dict[str, list[str]] = {}


def _route_key(hid: str, path: str) -> str:
    return hid + "::" + path


def _redirect_walk(start_rid: str, store: SiteGraph) -> tuple[list[str], str]:
    claimed: dict[str, bool] = {}
    chain: list[str] = []
    terminal: str = ""
    stack: deque[str] = deque()

    def step(here_rid: str) -> None:
        nonlocal terminal
        if here_rid in claimed:
            return
        claimed[here_rid] = True
        chain.append(here_rid)
        targets = store.redirects.get(here_rid, [])
        if len(targets) == 0:
            terminal = here_rid
            return
        ordered = sorted(targets)
        stack.clear()
        for tgt in ordered:
            stack.append(tgt)
        while stack:
            step(stack.pop())
        if terminal == "":
            terminal = here_rid

    step(start_rid)
    return chain, terminal


def fresh_site_graph() -> SiteGraph:
    return SiteGraph()


def register_host(
    hid: str,
    role: str,
    indexed: bool,
    store: SiteGraph | None = None,
) -> SiteGraph:
    s = store
    if s is None:
        s = fresh_site_graph()
    if hid in s.hosts:
        raise ValueError("duplicate host")
    s.hosts[hid] = SiteHost(hid=hid, role=role, indexed=indexed)
    return s


def register_route(hid: str, path: str, status: int, store: SiteGraph) -> str:
    if hid not in store.hosts:
        raise KeyError(hid)
    rid = _route_key(hid, path)
    if rid in store.routes:
        raise ValueError("duplicate route")
    store.routes[rid] = SiteRoute(rid=rid, hid=hid, path=path, status=status)
    store.redirects.setdefault(rid, [])
    return rid


def add_path_redirect(from_hid: str, path: str, to_hid: str, store: SiteGraph) -> None:
    from_rid = _route_key(from_hid, path)
    to_rid = _route_key(to_hid, path)
    if from_rid not in store.routes or to_rid not in store.routes:
        raise KeyError("unknown route")
    outs = store.redirects.setdefault(from_rid, [])
    outs.append(to_rid)


def redirect_chain(hid: str, path: str, store: SiteGraph) -> list[str]:
    rid = _route_key(hid, path)
    if rid not in store.routes:
        raise KeyError(rid)
    chain, _ = _redirect_walk(rid, store)
    return chain


def terminal_route(hid: str, path: str, store: SiteGraph) -> dict:
    rid = _route_key(hid, path)
    if rid not in store.routes:
        raise KeyError(rid)
    chain, terminal = _redirect_walk(rid, store)
    end_rid = terminal
    if end_rid == "":
        end_rid = chain[len(chain) - 1]
    end = store.routes[end_rid]
    return {"host": end.hid, "path": end.path, "status": end.status}


def count_indexed_duplicates(store: SiteGraph) -> int:
    n = 0
    for hid in sorted(store.hosts.keys()):
        host = store.hosts[hid]
        if host.indexed and host.role != ROLE_CANONICAL:
            n += 1
    return n


def proves_canonical_terminus(hid: str, path: str, store: SiteGraph) -> bool:
    term = terminal_route(hid, path, store)
    host = store.hosts.get(term["host"])
    if host is None:
        return False
    return host.role == ROLE_CANONICAL and term["status"] == 200
