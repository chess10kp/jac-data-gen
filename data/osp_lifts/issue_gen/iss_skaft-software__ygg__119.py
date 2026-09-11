"""skaft-software/ygg#119 — static agent workflow phase waves."""

from __future__ import annotations


class WorkflowStore:
    def __init__(self) -> None:
        self.deps: dict[str, list[str]] = {}
        self.phases: set[str] = set()


def load_workflow(
    phases: list[str],
    requires: list[tuple[str, str]],
) -> WorkflowStore:
    w = WorkflowStore()
    for p in phases:
        w.phases.add(p)
        w.deps.setdefault(p, [])
    for dst, src in requires:
        if dst in w.phases and src in w.phases:
            w.deps[dst].append(src)
    return w


def phase_waves(wf: WorkflowStore) -> list[list[str]] | None:
    indeg = {p: len(wf.deps.get(p, [])) for p in wf.phases}
    waves: list[list[str]] = []
    ready = sorted([p for p, d in indeg.items() if d == 0])
    while ready:
        waves.append(ready)
        nxt: list[str] = []
        for base in ready:
            for phase in wf.phases:
                if base in wf.deps.get(phase, []):
                    indeg[phase] -= 1
                    if indeg[phase] == 0:
                        nxt.append(phase)
        ready = sorted(nxt)
    return waves if sum(len(x) for x in waves) == len(wf.phases) else None


def downstream_phases(wf: WorkflowStore, phase: str) -> list[str]:
    if phase not in wf.phases:
        return []
    rev: dict[str, list[str]] = {p: [] for p in wf.phases}
    for dst, srcs in wf.deps.items():
        for src in srcs:
            rev[src].append(dst)
    seen: set[str] = set()
    stack = [phase]
    out: list[str] = []
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        if cur != phase:
            out.append(cur)
        for nxt in sorted(rev.get(cur, [])):
            stack.append(nxt)
    return sorted(out)
