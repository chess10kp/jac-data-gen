"""Herd-OS/herd#1050 — review workflow status transition reachability."""

from __future__ import annotations

from collections import deque

CANONICAL = {"approved", "changes_requested", "failed", "timed_out", "unparseable"}


class ReviewWorkflow:
    def __init__(self) -> None:
        self._statuses: set[str] = set()
        self._next: dict[str, list[str]] = {}


def load_review_workflow(
    statuses: list[str],
    transition_edges: list[tuple[str, str]],
) -> ReviewWorkflow:
    wf = ReviewWorkflow()
    for st in statuses:
        wf._statuses.add(st)
        wf._next.setdefault(st, [])
    for src, dst in transition_edges:
        if src in wf._statuses and dst in wf._statuses:
            wf._next.setdefault(src, []).append(dst)
    return wf


def reachable_statuses(store: ReviewWorkflow, from_status: str) -> list[str]:
    if from_status not in store._statuses:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([from_status])
    while queue:
        cur = queue.popleft()
        for nxt in store._next.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def can_transition(store: ReviewWorkflow, from_status: str, to_status: str) -> bool:
    if from_status not in store._statuses or to_status not in store._statuses:
        return False
    return to_status in store._next.get(from_status, [])


def normalize_status(store: ReviewWorkflow, raw: str) -> str | None:
    aliases = {"timeout": "timed_out", "timedout": "timed_out"}
    mapped = aliases.get(raw, raw)
    if mapped in store._statuses:
        return mapped
    if mapped in CANONICAL:
        return mapped if mapped in store._statuses else None
    return None
