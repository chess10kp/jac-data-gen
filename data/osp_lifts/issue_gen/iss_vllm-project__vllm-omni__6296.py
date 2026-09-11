"""vllm-project/vllm-omni#6296 — NPU Moss-TTS work-item dependency planner.

The Moss-TTS-Local-v1.5 NPU optimization proposal lays out a vocoder serial
chain (C operator adapt → B StatePool+bf16 → A vocoder graph → E1 skip compile)
and an independent talker track (D). Contributors need transitive downstream
impact and eligibility gates before claiming items. Hand-rolled adjacency dicts
plus deque BFS closure with visited sets.
"""

from __future__ import annotations

from collections import deque


class NpuPlan:
    """Mutable work-item index; fresh instance per test."""

    def __init__(self) -> None:
        self._fwd: dict[str, list[str]] = {}
        self._preds: dict[str, list[str]] = {}
        self._items: set[str] = set()

    def load(self, items: list[str], edges: list[tuple[str, str]]) -> None:
        # edges: (prerequisite, dependent)
        self._items = set(items)
        self._fwd = {it: [] for it in items}
        self._preds = {it: [] for it in items}
        for prereq, dep in edges:
            if prereq in self._items and dep in self._items:
                self._fwd[prereq].append(dep)
                self._preds[dep].append(prereq)

    def downstream_impact(self, stage_id: str) -> list[str]:
        if stage_id not in self._items:
            return []
        seen: set[str] = {stage_id}
        queue: deque[str] = deque(self._fwd.get(stage_id, []))
        hits: list[str] = []
        while queue:
            cur = queue.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            hits.append(cur)
            for nxt in self._fwd.get(cur, []):
                if nxt not in seen:
                    queue.append(nxt)
        return sorted(hits)

    def eligible_claims(self, done: set[str]) -> list[str]:
        out: list[str] = []
        for item in sorted(self._items):
            if item in done:
                continue
            reqs = self._preds.get(item, [])
            if all(r in done for r in reqs):
                out.append(item)
        return out
