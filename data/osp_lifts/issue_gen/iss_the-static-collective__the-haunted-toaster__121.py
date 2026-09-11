"""the-static-collective/the-haunted-toaster#121 — Receipt dependency closure graph.

Reconstruction receipts reference other receipts; stack walk gathers the
dependency closure needed before exact-return artifact resolution.
"""

from __future__ import annotations


class ReceiptGraph:
    def __init__(self) -> None:
        self.receipts: set[str] = set()
        self.needs: dict[str, list[str]] = {}


def load_receipt_graph(
    receipts: list[str],
    need_edges: list[tuple[str, str]],
) -> ReceiptGraph:
    g = ReceiptGraph()
    for rid in receipts:
        g.receipts.add(rid)
        g.needs.setdefault(rid, [])
    for dep, receipt in need_edges:
        if dep in g.receipts and receipt in g.receipts:
            g.needs.setdefault(receipt, []).append(dep)
    return g


def _closure(g: ReceiptGraph, receipt_id: str) -> set[str]:
    seen: set[str] = set()
    stack: list[str] = [receipt_id]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for dep in sorted(g.needs.get(cur, [])):
            stack.append(dep)
    return seen


def dependency_closure(g: ReceiptGraph, receipt_id: str) -> list[str]:
    if receipt_id not in g.receipts:
        return []
    return sorted(_closure(g, receipt_id))


def unresolved(g: ReceiptGraph, resolved: list[str]) -> list[str]:
    done = set(resolved)
    pending: list[str] = []
    for rid in sorted(g.receipts):
        if rid in done:
            continue
        deps = [d for d in dependency_closure(g, rid) if d != rid]
        if all(d in done for d in deps):
            pending.append(rid)
    return pending
