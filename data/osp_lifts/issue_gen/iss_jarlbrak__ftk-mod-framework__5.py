"""jarlbrak/ftk-mod-framework#5 — Campaign spec dependency DAG readiness."""

from __future__ import annotations


class SpecGraph:
    def __init__(self) -> None:
        self.specs: set[str] = set()
        self.blocked_by: dict[str, list[str]] = {}


def load_spec_graph(
    specs: list[str],
    edges: list[tuple[str, str]],
) -> SpecGraph:
    g = SpecGraph()
    for sid in specs:
        g.specs.add(sid)
        g.blocked_by.setdefault(sid, [])
    for blocker, blocked in edges:
        if blocker in g.specs and blocked in g.specs:
            g.blocked_by.setdefault(blocked, []).append(blocker)
    return g


def _upstream_ids(g: SpecGraph, spec_id: str) -> set[str]:
    seen: set[str] = set()
    stack: list[str] = [spec_id]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for blk in sorted(g.blocked_by.get(cur, [])):
            stack.append(blk)
    return seen


def prerequisites(g: SpecGraph, spec_id: str) -> list[str]:
    if spec_id not in g.specs:
        return []
    return sorted(_upstream_ids(g, spec_id))


def ready_specs(g: SpecGraph, completed: list[str]) -> list[str]:
    done = set(completed)
    ready: list[str] = []
    for sid in sorted(g.specs):
        if sid in done:
            continue
        needs = [p for p in prerequisites(g, sid) if p != sid]
        if all(p in done for p in needs):
            ready.append(sid)
    return ready
