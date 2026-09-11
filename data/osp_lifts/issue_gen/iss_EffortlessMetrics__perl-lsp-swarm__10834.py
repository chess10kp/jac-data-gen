"""EffortlessMetrics/perl-lsp-swarm#10834 — propagate receivers at program points."""

from __future__ import annotations

from collections import deque


class CfgStore:
    def __init__(self, entry: str) -> None:
        self.entry = entry
        self.points: set[str] = set()
        self.flow: dict[str, list[str]] = {}
        self.assigns: dict[str, dict[str, str]] = {}
        self.snapshots: dict[str, dict[str, str]] = {}


def load_cfg(
    points: list[str],
    edges: list[tuple[str, str]],
    assignments: list[tuple[str, str, str]],
    entry: str,
) -> CfgStore:
  # assignments: (program_point, binding_key, receiver_class)
    g = CfgStore(entry=entry)
    for pid in points:
        g.points.add(pid)
        g.flow.setdefault(pid, [])
        g.assigns.setdefault(pid, {})
    for src, dst in edges:
        g.flow.setdefault(src, []).append(dst)
        g.flow.setdefault(dst, [])
    for pt, binding, receiver in assignments:
        if pt in g.points:
            g.assigns[pt][binding] = receiver
    return g


def propagate_receivers(g: CfgStore) -> dict[str, dict[str, str]]:
    state: dict[str, str] = {}
    claimed: set[str] = set()
    q: deque[str] = deque([g.entry])
    out: dict[str, dict[str, str]] = {}
    while q:
        pt = q.popleft()
        if pt in claimed:
            continue
        claimed.add(pt)
        for binding, recv in g.assigns.get(pt, {}).items():
            if recv:
                state[binding] = recv
        out[pt] = dict(state)
        for nxt in sorted(g.flow.get(pt, [])):
            if nxt not in claimed:
                q.append(nxt)
    g.snapshots = out
    return out


def receivers_at(g: CfgStore, point: str, binding: str) -> str | None:
    if point not in g.points:
        return None
    if not g.snapshots:
        propagate_receivers(g)
    return g.snapshots.get(point, {}).get(binding)
