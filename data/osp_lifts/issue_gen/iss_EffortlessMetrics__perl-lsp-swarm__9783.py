"""EffortlessMetrics/perl-lsp-swarm#9783 — Mojo::Promise continuation tuple propagation."""

from collections import deque
from typing import Any


def build_continuation_graph(facts: list[dict[str, Any]]) -> dict[str, Any]:
    adj: dict[str, list[str]] = {}
    parent: dict[str, str] = {}
    meta: dict[str, dict[str, Any]] = {}
    for fact in facts:
        fid = fact["id"]
        meta[fid] = fact
        adj.setdefault(fid, [])
        pid = fact.get("parent")
        if pid:
            adj.setdefault(pid, [])
            adj[pid].append(fid)
            parent[fid] = pid
    for node in adj:
        adj[node] = sorted(adj[node])
    return {"adj": adj, "parent": parent, "meta": meta}


def reachable_continuations(root: str, adj: dict[str, list[str]]) -> list[str]:
    seen: set[str] = set()
    order: list[str] = []
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        order.append(cur)
        for nxt in adj.get(cur, []):
            queue.append(nxt)
    return order


def _apply_continuation(
    pf: tuple[Any, ...],
    pr: tuple[Any, ...] | None,
    fact: dict[str, Any],
) -> tuple[tuple[Any, ...], tuple[Any, ...] | None]:
    edge = fact.get("edge") or "then"
    if edge == "finally":
        return pf, pr
    if edge == "catch":
        if pr is not None:
            rf = fact.get("result_f")
            rr = fact.get("result_r")
            out_f = tuple(rf) if rf is not None else pf
            out_r = tuple(rr) if rr is not None else None
            return out_f, out_r
        return pf, pr
    if pr is None:
        rf = fact.get("result_f")
        if rf is not None:
            return (rf if isinstance(rf, tuple) else (rf,)), fact.get("result_r")
        return pf, pr
    rr = fact.get("result_r")
    if rr is not None:
        rf = fact.get("result_f")
        out_f = tuple(rf) if rf is not None else ()
        out_r = rr if isinstance(rr, tuple) else (rr,)
        return out_f, out_r
    return pf, pr


def propagate_continuation_tuples(
    root: str,
    adj: dict[str, list[str]],
    meta: dict[str, dict[str, Any]],
) -> dict[str, tuple[tuple[Any, ...], tuple[Any, ...] | None]]:
    out: dict[str, tuple[tuple[Any, ...], tuple[Any, ...] | None]] = {}
    for fid in reachable_continuations(root, adj):
        fact = meta[fid]
        if fid == root:
            tf = fact.get("tuple_f") or ()
            tr = fact.get("tuple_r")
            out[fid] = (tuple(tf), tuple(tr) if tr is not None else None)
            continue
        pf, pr = out[fact["parent"]]
        out[fid] = _apply_continuation(pf, pr, fact)
    return out


def flatten_admitted_thenables(
    adj: dict[str, list[str]],
    meta: dict[str, dict[str, Any]],
    admitted: set[str],
) -> tuple[dict[str, list[str]], list[str]]:
    new_adj = {node: list(children) for node, children in adj.items()}
    flattened: list[str] = []
    for fid in sorted(meta):
        fact = meta[fid]
        if not fact.get("thenable") or fid not in admitted:
            continue
        flattened.append(fid)
        pid = fact.get("parent")
        if not pid:
            continue
        bridged = [c for c in new_adj.get(pid, []) if c != fid]
        bridged.extend(new_adj.get(fid, []))
        new_adj[pid] = sorted(set(bridged))
    return new_adj, flattened


def continuation_paths(root: str, adj: dict[str, list[str]]) -> list[tuple[str, ...]]:
    paths: list[tuple[str, ...]] = []

    def _walk(node: str, trail: tuple[str, ...]) -> None:
        ntrail = trail + (node,)
        children = adj.get(node, [])
        if not children:
            paths.append(ntrail)
            return
        for child in children:
            if child in ntrail:
                paths.append(ntrail + (child,))
                continue
            _walk(child, ntrail)

    _walk(root, ())
    return sorted(paths)
