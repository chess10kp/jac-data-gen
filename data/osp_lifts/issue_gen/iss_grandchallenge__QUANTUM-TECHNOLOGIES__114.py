"""grandchallenge/QUANTUM-TECHNOLOGIES#114 — decoder pipeline stage ordering."""

from __future__ import annotations

from collections import deque


class CycleError(Exception):
    pass


class DecoderPipeline:
    def __init__(self) -> None:
        self._stages: set[str] = set()
        self._requires: dict[str, list[str]] = {}


def load_decoder_dag(
    stage_names: list[str],
    require_edges: list[tuple[str, str]],
) -> DecoderPipeline:
    pipe = DecoderPipeline()
    for stage in stage_names:
        pipe._stages.add(stage)
        pipe._requires.setdefault(stage, [])
    for upstream, downstream in require_edges:
        if upstream in pipe._stages and downstream in pipe._stages:
            pipe._requires.setdefault(downstream, []).append(upstream)
    return pipe


def execution_order(pipe: DecoderPipeline) -> list[str]:
    indegree: dict[str, int] = {s: 0 for s in pipe._stages}
    rev: dict[str, list[str]] = {s: [] for s in pipe._stages}
    for stage, reqs in pipe._requires.items():
        for _ in reqs:
            indegree[stage] += 1
        for up in reqs:
            rev[up].append(stage)
    order: list[str] = []
    ready = sorted(s for s, d in indegree.items() if d == 0)
    visited: set[str] = set()
    while ready:
        node = ready.pop(0)
        if node in visited:
            continue
        visited.add(node)
        order.append(node)
        for other in rev.get(node, []):
            indegree[other] -= 1
            if indegree[other] == 0 and other not in visited:
                ready.append(other)
        ready = sorted(ready)
    if len(visited) != len(pipe._stages):
        raise CycleError("stage dependency cycle")
    return order


def stage_reachable(pipe: DecoderPipeline, root: str) -> list[str]:
    if root not in pipe._stages:
        return []
    rev: dict[str, list[str]] = {s: [] for s in pipe._stages}
    for stage, reqs in pipe._requires.items():
        for up in reqs:
            rev[up].append(stage)
    seen: set[str] = set()
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for nxt in rev.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def compile_validate_decode_order(pipe: DecoderPipeline) -> list[str]:
    order = execution_order(pipe)
    phases = ["compile", "validate", "decode"]
    out: list[str] = []
    for phase in phases:
        if phase in order:
            out.append(phase)
    for stage in order:
        if stage not in out:
            out.append(stage)
    return out
