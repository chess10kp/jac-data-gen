"""edjafarov/kiagent-core#75 — bounded recursive CTE reachability off sync query_sql."""

from __future__ import annotations

from collections import deque

DEFAULT_ROW_CAP = 500


class _TableNode:
    __slots__ = ("tid", "row_count", "out")

    def __init__(self, tid: str, row_count: int) -> None:
        self.tid = tid
        self.row_count = row_count
        self.out: list[_TableNode] = []


def _sorted_children(nd: _TableNode) -> list[_TableNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.tid)
    return kids


def _find_table(tid: str, store: dict) -> _TableNode | None:
    nmap = store["nodes"]
    if tid in nmap:
        return nmap[tid]
    return None


def _walk_closure(start_id: str, store: dict, row_cap: int) -> tuple[list[str], int, bool]:
    tables = store["tables"]
    claimed: dict[str, bool] = {}
    order: list[str] = []
    rows_used = 0
    truncated = False
    stack: deque[str] = deque([start_id])
    while stack:
        tid = stack.pop()
        if tid in claimed:
            continue
        if row_cap > 0 and rows_used + tables[tid] > row_cap:
            truncated = True
            break
        claimed[tid] = True
        order.append(tid)
        rows_used += tables[tid]
        nd = _find_table(tid, store)
        if nd is not None:
            kids = _sorted_children(nd)
            for child in reversed(kids):
                stack.append(child.tid)
    return order, rows_used, truncated


def fresh_query_store() -> dict:
    return {"tables": {}, "refs": {}, "nodes": {}}


def register_table(table_id: str, row_count: int, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_query_store()
    tmap = s["tables"]
    tmap[table_id] = row_count
    refs = s["refs"]
    if table_id not in refs:
        refs[table_id] = []
    nmap = s["nodes"]
    nd = _TableNode(tid=table_id, row_count=row_count)
    nmap[table_id] = nd
    return s


def add_reference(source_id: str, target_id: str, store: dict) -> None:
    tmap = store["tables"]
    if source_id not in tmap or target_id not in tmap:
        raise KeyError("unknown table id")
    src_nd = _find_table(source_id, store)
    tgt_nd = _find_table(target_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.tid == target_id for ex in src_nd.out)
        if not seen:
            src_nd.out.append(tgt_nd)
    outs = store["refs"]
    if source_id not in outs:
        outs[source_id] = []
    lst = outs[source_id]
    if target_id not in lst:
        lst.append(target_id)


def recursive_reachable(start_id: str, store: dict, row_cap: int = DEFAULT_ROW_CAP) -> list[str]:
    if start_id not in store["tables"]:
        raise KeyError(start_id)
    start_nd = _find_table(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    order, _, _ = _walk_closure(start_id, store, row_cap)
    return order


def query_work_units(start_id: str, store: dict) -> int:
    order = recursive_reachable(start_id, store, row_cap=0)
    tmap = store["tables"]
    total = 0
    for tid in order:
        total += tmap[tid]
    return total


def bounded_reach_report(start_id: str, store: dict, row_cap: int = DEFAULT_ROW_CAP) -> dict:
    if start_id not in store["tables"]:
        raise KeyError(start_id)
    start_nd = _find_table(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    order, rows_used, truncated = _walk_closure(start_id, store, row_cap)
    return {"tables": order, "rows": rows_used, "truncated": truncated}
