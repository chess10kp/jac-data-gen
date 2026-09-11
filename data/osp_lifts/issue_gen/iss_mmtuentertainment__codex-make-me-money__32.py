"""mmtuentertainment/codex-make-me-money#32 — Repair lineage with predecessor evidence.

Reconciliation records preserve predecessor chains and failure evidence via
parent pointers and recursive ascent over the repair lineage graph.
"""

from __future__ import annotations


class RepairLedger:
    def __init__(self) -> None:
        self.parent_of: dict[str, str | None] = {}
        self.failed: set[str] = set()


def load_ledger(
    records: list[str],
    lineage: list[tuple[str, str]],
    failed: list[str],
) -> RepairLedger:
    ledger = RepairLedger()
    for rid in records:
        ledger.parent_of[rid] = None
    for child, parent in lineage:
        if child in ledger.parent_of and parent in ledger.parent_of:
            ledger.parent_of[child] = parent
    ledger.failed = set(failed)
    return ledger


def _walk_predecessors(ledger: RepairLedger, start: str, acc: list[str]) -> None:
    cur = ledger.parent_of.get(start)
    while cur is not None:
        acc.append(cur)
        cur = ledger.parent_of.get(cur)


def lineage_trail(ledger: RepairLedger, record_id: str) -> list[str]:
    if record_id not in ledger.parent_of:
        return []
    acc: list[str] = [record_id]
    _walk_predecessors(ledger, record_id, acc)
    return sorted(set(acc))


def failure_evidence(ledger: RepairLedger, record_id: str) -> list[str]:
    trail = set(lineage_trail(ledger, record_id))
    hits = [rid for rid in ledger.failed if rid in trail]
    return sorted(hits)
