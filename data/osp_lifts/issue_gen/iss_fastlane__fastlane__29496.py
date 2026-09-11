"""fastlane/fastlane#29496 — buffered IO sync inflates reachable build-phase cost."""

from __future__ import annotations

from collections import deque

SYNC_PENALTY_MS = 12000


class _PhaseNode:
    __slots__ = ("pid", "base_ms", "out")

    def __init__(self, pid: str, base_ms: int) -> None:
        self.pid = pid
        self.base_ms = base_ms
        self.out: list[_PhaseNode] = []


def _sorted_out(nd: _PhaseNode) -> list[_PhaseNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.pid)
    return kids


def _find_phase(pid: str, store: dict) -> _PhaseNode | None:
    nmap = store["nodes"]
    if pid in nmap:
        return nmap[pid]
    return None


def _effective_ms(nd: _PhaseNode, sync_io: bool) -> int:
    if sync_io and nd.pid == "launch_screen":
        return nd.base_ms + SYNC_PENALTY_MS
    return nd.base_ms


def _reach_order(start_id: str, store: dict) -> list[str]:
    claimed: dict[str, bool] = {}
    order: list[str] = []
    stack: deque[str] = deque([start_id])
    while stack:
        pid = stack.pop()
        if pid in claimed:
            continue
        claimed[pid] = True
        order.append(pid)
        nd = _find_phase(pid, store)
        if nd is not None:
            for child in reversed(_sorted_out(nd)):
                stack.append(child.pid)
    return order


def fresh_build_store() -> dict:
    return {"phases": {}, "deps": {}, "rev": {}, "nodes": {}}


def register_phase(phase_id: str, base_ms: int, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_build_store()
    s["phases"][phase_id] = base_ms
    deps = s["deps"]
    if phase_id not in deps:
        deps[phase_id] = []
    rev = s["rev"]
    if phase_id not in rev:
        rev[phase_id] = []
    nd = _PhaseNode(pid=phase_id, base_ms=base_ms)
    s["nodes"][phase_id] = nd
    return s


def add_phase_dependency(source_id: str, target_id: str, store: dict) -> None:
    pmap = store["phases"]
    if source_id not in pmap or target_id not in pmap:
        raise KeyError("unknown phase id")
    if source_id == target_id:
        return
    src_nd = _find_phase(source_id, store)
    tgt_nd = _find_phase(target_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.pid == target_id for ex in src_nd.out)
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


def reachable_phases(start_id: str, store: dict) -> list[str]:
    if start_id not in store["phases"]:
        raise KeyError(start_id)
    start_nd = _find_phase(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for pid in _reach_order(start_id, store):
        if pid != start_id:
            reach.append(pid)
    return reach


def build_duration_ms(start_id: str, store: dict, sync_io: bool = False) -> int:
    if start_id not in store["phases"]:
        raise KeyError(start_id)
    start_nd = _find_phase(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    total = 0
    for pid in _reach_order(start_id, store):
        nd = _find_phase(pid, store)
        if nd is not None:
            total += _effective_ms(nd, sync_io)
    return total


def build_report(start_id: str, store: dict, sync_io: bool = False) -> dict:
    reach = reachable_phases(start_id, store)
    direct = list(store["deps"].get(start_id, []))
    return {
        "direct": direct,
        "reach": reach,
        "reach_count": len(reach),
        "duration_ms": build_duration_ms(start_id, store, sync_io),
        "sync_io": sync_io,
    }
