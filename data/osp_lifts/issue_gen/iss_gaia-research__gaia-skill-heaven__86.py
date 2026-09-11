"""gaia-research/gaia-skill-heaven#86 — Termux I/O penalty on boot-step reach cost."""

from __future__ import annotations

from collections import deque

TERMUX_IO_PENALTY_MS = 8000


class _BootNode:
    __slots__ = ("sid", "base_ms", "out")

    def __init__(self, sid: str, base_ms: int) -> None:
        self.sid = sid
        self.base_ms = base_ms
        self.out: list[_BootNode] = []


def _sorted_out(nd: _BootNode) -> list[_BootNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.sid)
    return kids


def _find_step(sid: str, store: dict) -> _BootNode | None:
    nmap = store["nodes"]
    if sid in nmap:
        return nmap[sid]
    return None


def _effective_ms(nd: _BootNode, termux_io: bool) -> int:
    if termux_io and (nd.sid == "npm_unpack" or nd.sid == "copy_skills"):
        return nd.base_ms + TERMUX_IO_PENALTY_MS
    return nd.base_ms


def _reach_order(start_id: str, store: dict) -> list[str]:
    claimed: dict[str, bool] = {}
    order: list[str] = []
    stack: deque[str] = deque([start_id])
    while stack:
        sid = stack.pop()
        if sid in claimed:
            continue
        claimed[sid] = True
        order.append(sid)
        nd = _find_step(sid, store)
        if nd is not None:
            for child in reversed(_sorted_out(nd)):
                stack.append(child.sid)
    return order


def fresh_boot_store() -> dict:
    return {"steps": {}, "deps": {}, "rev": {}, "nodes": {}}


def register_boot_step(step_id: str, base_ms: int, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_boot_store()
    s["steps"][step_id] = base_ms
    deps = s["deps"]
    if step_id not in deps:
        deps[step_id] = []
    rev = s["rev"]
    if step_id not in rev:
        rev[step_id] = []
    nd = _BootNode(sid=step_id, base_ms=base_ms)
    s["nodes"][step_id] = nd
    return s


def add_boot_dependency(source_id: str, target_id: str, store: dict) -> None:
    smap = store["steps"]
    if source_id not in smap or target_id not in smap:
        raise KeyError("unknown boot step id")
    if source_id == target_id:
        return
    src_nd = _find_step(source_id, store)
    tgt_nd = _find_step(target_id, store)
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
    revs = store["rev"]
    if target_id not in revs:
        revs[target_id] = []
    if source_id not in revs[target_id]:
        revs[target_id].append(source_id)
        revs[target_id] = sorted(revs[target_id])


def direct_downstream(step_id: str, store: dict) -> list[str]:
    if step_id not in store["steps"]:
        raise KeyError(step_id)
    return list(store["deps"].get(step_id, []))


def reachable_steps(start_id: str, store: dict) -> list[str]:
    if start_id not in store["steps"]:
        raise KeyError(start_id)
    start_nd = _find_step(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for sid in _reach_order(start_id, store):
        if sid != start_id:
            reach.append(sid)
    return reach


def boot_duration_ms(start_id: str, store: dict, termux_io: bool = False) -> int:
    if start_id not in store["steps"]:
        raise KeyError(start_id)
    start_nd = _find_step(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    total = 0
    for sid in _reach_order(start_id, store):
        nd = _find_step(sid, store)
        if nd is not None:
            total += _effective_ms(nd, termux_io)
    return total


def boot_report(start_id: str, store: dict, termux_io: bool = False) -> dict:
    reach = reachable_steps(start_id, store)
    direct = direct_downstream(start_id, store)
    return {
        "direct": direct,
        "reach": reach,
        "reach_count": len(reach),
        "duration_ms": boot_duration_ms(start_id, store, termux_io),
        "termux_io": termux_io,
    }
