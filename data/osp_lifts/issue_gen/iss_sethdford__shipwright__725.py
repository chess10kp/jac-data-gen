"""sethdford/shipwright#725 — Cross-Pipeline Result Cache with Change-Based Invalidation."""

from __future__ import annotations

from collections import deque


class PipelineCache:
    def __init__(self) -> None:
        self._pipelines: set[str] = set()
        self._downstream: dict[str, list[str]] = {}
        self._memo_parent: dict[str, str] = {}
        self._cached: dict[str, str] = {}


def build_cache(
    pipelines: list[str],
    depends: list[tuple[str, str]],
    memo_of: list[tuple[str, str]] | None = None,
) -> PipelineCache:
    c = PipelineCache()
    c._pipelines = set(pipelines)
    for pid in pipelines:
        c._downstream.setdefault(pid, [])
    for upstream, downstream in depends:
        if upstream in c._pipelines and downstream in c._pipelines:
            c._downstream.setdefault(upstream, []).append(downstream)
            c._downstream.setdefault(downstream, c._downstream.get(downstream, []))
    for child, parent in memo_of or []:
        if child in c._pipelines and parent in c._pipelines:
            c._memo_parent[child] = parent
    return c


def store_result(cache: PipelineCache, pipeline_id: str, payload: str) -> bool:
    if pipeline_id not in cache._pipelines:
        return False
    cache._cached[pipeline_id] = payload
    return True


def read_result(cache: PipelineCache, pipeline_id: str) -> str | None:
    return cache._cached.get(pipeline_id)


def _memo_ancestor_chain(cache: PipelineCache, pipeline_id: str) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    cur = cache._memo_parent.get(pipeline_id)
    while cur is not None and cur not in seen:
        seen.add(cur)
        out.append(cur)
        cur = cache._memo_parent.get(cur)
    return sorted(out)


def downstream_pipelines(cache: PipelineCache, pipeline_id: str) -> list[str]:
    if pipeline_id not in cache._pipelines:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([pipeline_id])
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in cache._downstream.get(cur, []):
            if nxt not in seen:
                if nxt != pipeline_id:
                    hits.append(nxt)
                q.append(nxt)
    return sorted(set(hits))


def _collect_invalidate_targets(cache: PipelineCache, pipeline_id: str) -> list[str]:
    targets: set[str] = {pipeline_id}
    targets.update(downstream_pipelines(cache, pipeline_id))
    targets.update(_memo_ancestor_chain(cache, pipeline_id))
    return sorted(targets)


def invalidate_on_change(cache: PipelineCache, pipeline_id: str) -> list[str]:
    if pipeline_id not in cache._pipelines:
        return []
    cleared: list[str] = []
    for pid in _collect_invalidate_targets(cache, pipeline_id):
        if pid in cache._cached:
            del cache._cached[pid]
            cleared.append(pid)
    return cleared
