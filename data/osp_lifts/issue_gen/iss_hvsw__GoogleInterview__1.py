"""hvsw/GoogleInterview#1 — graph adjacency BFS reach and cycle detection."""

from __future__ import annotations

from collections import deque


class _GNode:
    __slots__ = ("nid", "out")

    def __init__(self, nid: str) -> None:
        self.nid = nid
        self.out: list[_GNode] = []


def _sorted_out(nd: _GNode) -> list[_GNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.nid)
    return kids


def _find_node(nid: str, store: dict) -> _GNode | None:
    nmap = store["nodes"]
    if nid in nmap:
        return nmap[nid]
    return None


def _dfs_order(start_id: str, store: dict) -> list[str]:
    claimed: dict[str, bool] = {}
    order: list[str] = []
    queue: deque[str] = deque([start_id])
    nodes = store["nodes"]
    while queue:
        nid = queue.popleft()
        if nid in claimed:
            continue
        claimed[nid] = True
        order.append(nid)
        nd = nodes.get(nid)
        if nd is not None:
            for child in reversed(_sorted_out(nd)):
                queue.appendleft(child.nid)
    return order


def _cycle_probe(start_id: str, store: dict) -> bool:
    claimed: dict[str, bool] = {}
    stack: list[str] = [start_id]
    nodes = store["nodes"]
    while len(stack) > 0:
        nid = stack.pop()
        if nid in claimed:
            return True
        claimed[nid] = True
        nd = nodes.get(nid)
        if nd is not None:
            for child in _sorted_out(nd):
                stack.append(child.nid)
    return False


def fresh_graph_store() -> dict:
    return {"nodes": {}, "deps": {}, "rev": {}}


def register_node(nid: str, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_graph_store()
    nmap = s["nodes"]
    if nid in nmap:
        return s
    deps = s["deps"]
    if nid not in deps:
        deps[nid] = []
    revs = s["rev"]
    if nid not in revs:
        revs[nid] = []
    nd = _GNode(nid=nid)
    nmap[nid] = nd
    return s


def add_graph_edge(source_id: str, target_id: str, store: dict) -> None:
    nmap = store["nodes"]
    if source_id not in nmap or target_id not in nmap:
        raise KeyError("unknown node id")
    if source_id == target_id:
        return
    src_nd = _find_node(source_id, store)
    tgt_nd = _find_node(target_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.nid == target_id for ex in src_nd.out)
        if not seen:
            src_nd.out.append(tgt_nd)
    outs = store["deps"]
    if target_id not in outs[source_id]:
        outs[source_id].append(target_id)
        outs[source_id] = sorted(outs[source_id])
    revs = store["rev"]
    if source_id not in revs[target_id]:
        revs[target_id].append(source_id)
        revs[target_id] = sorted(revs[target_id])


def bfs_reach(start_id: str, store: dict) -> list[str]:
    if start_id not in store["nodes"]:
        raise KeyError(start_id)
    dist: dict[str, int] = {}
    dist[start_id] = 0
    queue: list[str] = [start_id]
    qi = 0
    while qi < len(queue):
        cur = queue[qi]
        qi += 1
        for dst in store["deps"].get(cur, []):
            if dst not in dist:
                dist[dst] = dist[cur] + 1
                queue.append(dst)
    reach: list[str] = []
    for nid in dist:
        if nid != start_id:
            reach.append(nid)
    reach = sorted(reach)
    return reach


def dfs_reach(start_id: str, store: dict) -> list[str]:
    if start_id not in store["nodes"]:
        raise KeyError(start_id)
    start_nd = _find_node(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for nid in _dfs_order(start_id, store):
        if nid != start_id:
            reach.append(nid)
    reach = sorted(reach)
    return reach


def detect_cycle(store: dict) -> bool:
    nmap = store["nodes"]
    for nid in sorted(nmap.keys()):
        if _cycle_probe(nid, store):
            return True
    return False


def graph_report(start_id: str, store: dict) -> dict:
    if start_id not in store["nodes"]:
        raise KeyError(start_id)
    bfs = bfs_reach(start_id, store)
    dfs = dfs_reach(start_id, store)
    return {
        "bfs_reach": bfs,
        "dfs_reach": dfs,
        "reach_count": len(bfs),
        "has_cycle": detect_cycle(store),
    }
