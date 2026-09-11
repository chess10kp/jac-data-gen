"""hashicorp/vault#32090 — bounded KV mount LIST scan vs counter endpoint billing."""

from __future__ import annotations

from collections import deque

DEFAULT_LIST_CAP = 500
MODE_LIST = "list"
MODE_ENDPOINT = "endpoint"


class _SecretNode:
    __slots__ = ("sid", "out")

    def __init__(self, sid: str) -> None:
        self.sid = sid
        self.out: list[_SecretNode] = []


def _sorted_out(nd: _SecretNode) -> list[_SecretNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.sid)
    return kids


def _find_mount(mid: str, store: dict) -> bool:
    return mid in store["mount_nodes"]


def _find_secret(sid: str, store: dict) -> _SecretNode | None:
    nmap = store["nodes"]
    if sid in nmap:
        return nmap[sid]
    return None


def _list_walk(start_id: str, list_cap: int) -> tuple[list[str], int, bool]:
    claimed: dict[str, bool] = {}
    order: list[str] = []
    list_calls = 0
    truncated = False
    queue: deque[str] = deque([start_id])
    nodes = _WALK_NODES
    while queue:
        sid = queue.popleft()
        if sid in claimed:
            continue
        if list_cap > 0 and list_calls >= list_cap:
            truncated = True
            break
        claimed[sid] = True
        order.append(sid)
        list_calls += 1
        nd = nodes.get(sid)
        if nd is not None:
            for child in reversed(_sorted_out(nd)):
                queue.appendleft(child.sid)
    return order, list_calls, truncated


_WALK_NODES: dict[str, _SecretNode] = {}


def fresh_vault_store() -> dict:
    return {
        "mounts": {},
        "secrets": {},
        "deps": {},
        "nodes": {},
        "mount_nodes": {},
        "roots": {},
        "counters": {},
    }


def register_mount(mid: str, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_vault_store()
    s["mounts"][mid] = True
    roots = s["roots"]
    if mid not in roots:
        roots[mid] = []
    counters = s["counters"]
    if mid not in counters:
        counters[mid] = 0
    s["mount_nodes"][mid] = True
    return s


def register_secret(sid: str, store: dict) -> dict:
    if sid in store["secrets"]:
        return store
    store["secrets"][sid] = True
    deps = store["deps"]
    if sid not in deps:
        deps[sid] = []
    nd = _SecretNode(sid=sid)
    store["nodes"][sid] = nd
    return store


def add_mount_root(mount_id: str, secret_id: str, store: dict) -> None:
    if mount_id not in store["mounts"]:
        raise KeyError(mount_id)
    register_secret(secret_id, store)
    roots = store["roots"]
    if secret_id not in roots[mount_id]:
        roots[mount_id].append(secret_id)
        roots[mount_id] = sorted(roots[mount_id])


def add_secret_child(source_id: str, target_id: str, store: dict) -> None:
    smap = store["secrets"]
    if source_id not in smap or target_id not in smap:
        raise KeyError("unknown secret id")
    if source_id == target_id:
        return
    src_nd = _find_secret(source_id, store)
    tgt_nd = _find_secret(target_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.sid == target_id for ex in src_nd.out)
        if not seen:
            src_nd.out.append(tgt_nd)
    outs = store["deps"]
    if source_id not in outs:
        outs[source_id] = []
    if target_id not in outs[source_id]:
        outs[source_id].append(target_id)
        outs[source_id] = sorted(outs[source_id])


def recursive_list_count(mount_id: str, store: dict, list_cap: int = 0) -> dict:
    if mount_id not in store["mounts"]:
        raise KeyError(mount_id)
    global _WALK_NODES
    _WALK_NODES = store["nodes"]
    roots = store["roots"].get(mount_id, [])
    order: list[str] = []
    list_calls = 0
    truncated = False
    for rid in roots:
        part_order, part_calls, part_trunc = _list_walk(rid, list_cap)
        list_calls += part_calls
        if part_trunc:
            truncated = True
        for sid in part_order:
            if sid not in order:
                order.append(sid)
        if truncated:
            break
    order = sorted(order)
    return {
        "secrets": order,
        "secret_count": len(order),
        "list_calls": list_calls,
        "truncated": truncated,
    }


def set_mount_counter(mount_id: str, count: int, store: dict) -> None:
    if mount_id not in store["mounts"]:
        raise KeyError(mount_id)
    store["counters"][mount_id] = count


def billing_report(mount_id: str, store: dict, use_endpoint: bool = False) -> dict:
    if mount_id not in store["mounts"]:
        raise KeyError(mount_id)
    if use_endpoint:
        cnt = store["counters"].get(mount_id, 0)
        return {
            "secret_count": cnt,
            "list_calls": 0,
            "mode": MODE_ENDPOINT,
            "truncated": False,
        }
    scan = recursive_list_count(mount_id, store, list_cap=0)
    return {
        "secret_count": scan["secret_count"],
        "list_calls": scan["list_calls"],
        "mode": MODE_LIST,
        "truncated": scan["truncated"],
    }
