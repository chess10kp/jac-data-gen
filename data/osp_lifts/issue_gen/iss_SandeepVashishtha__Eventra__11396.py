"""SandeepVashishtha/Eventra#11396 — Optimize GitHub Actions with Dependency Caching.

Models GitHub Actions workflow jobs as a dependency DAG. Cache keys derive from
lockfile hashes; restore order and invalidation sweeps use hand-rolled adjacency
dicts, deque BFS, and memoized ancestor chains before actions/cache steps land.
"""

from __future__ import annotations

from collections import deque


class WorkflowCacheGraph:
    def __init__(self) -> None:
        self.lockfile_hash: dict[str, str] = {}
        self.deps: dict[str, list[str]] = {}  # job -> upstream prerequisites
        self._ancestor_memo: dict[str, list[str]] = {}


def load_workflow_cache_graph(
    jobs: list[tuple[str, str]],
    depends: list[tuple[str, str]],
) -> WorkflowCacheGraph:
    g = WorkflowCacheGraph()
    for name, lf_hash in jobs:
        g.lockfile_hash[name] = lf_hash
        g.deps.setdefault(name, [])
    for job, upstream in depends:
        if job in g.deps and upstream in g.lockfile_hash:
            if upstream not in g.deps[job]:
                g.deps[job].append(upstream)
    return g


def cache_key(g: WorkflowCacheGraph, job: str) -> str:
    if job not in g.lockfile_hash:
        return ""
    return f"{job}::{g.lockfile_hash[job]}"


def memo_ancestors(g: WorkflowCacheGraph, job: str) -> list[str]:
    if job not in g.lockfile_hash:
        return []
    if job in g._ancestor_memo:
        return g._ancestor_memo[job]
    seen: set[str] = set()
    stack = list(g.deps.get(job, []))
    found: list[str] = []
    while stack:
        u = stack.pop()
        if u in seen:
            continue
        seen.add(u)
        if u != job:
            found.append(u)
        for parent in g.deps.get(u, []):
            if parent not in seen:
                stack.append(parent)
    out = sorted(found)
    g._ancestor_memo[job] = out
    return out


def restore_order(g: WorkflowCacheGraph, job: str) -> list[str]:
    anc = memo_ancestors(g, job)
    if not anc:
        return []
    anc_set = set(anc)
    indeg = {n: 0 for n in anc}
    adj: dict[str, list[str]] = {n: [] for n in anc}
    for n in anc:
        for parent in g.deps.get(n, []):
            if parent in anc_set:
                adj[parent].append(n)
                indeg[n] += 1
    q = deque(sorted(n for n in anc if indeg[n] == 0))
    order: list[str] = []
    while q:
        u = q.popleft()
        order.append(u)
        for v in sorted(adj[u]):
            indeg[v] -= 1
            if indeg[v] == 0:
                q.append(v)
    return order


def _reverse_deps(g: WorkflowCacheGraph) -> dict[str, list[str]]:
    rev: dict[str, list[str]] = {}
    for job, ups in g.deps.items():
        for upstream in ups:
            rev.setdefault(upstream, []).append(job)
    return rev


def downstream_jobs(g: WorkflowCacheGraph, changed_jobs: list[str]) -> list[str]:
    if not changed_jobs:
        return []
    rev = _reverse_deps(g)
    seeds = [j for j in changed_jobs if j in g.lockfile_hash]
    seen = set(seeds)
    q = deque(seeds)
    touched: list[str] = []
    while q:
        cur = q.popleft()
        for child in sorted(rev.get(cur, [])):
            if child in seen:
                continue
            seen.add(child)
            touched.append(child)
            q.append(child)
    return sorted(touched)


def cache_keys_to_bust(g: WorkflowCacheGraph, changed_jobs: list[str]) -> list[str]:
    keys = [cache_key(g, j) for j in changed_jobs if j in g.lockfile_hash]
    keys.extend(cache_key(g, j) for j in downstream_jobs(g, changed_jobs))
    return sorted(set(k for k in keys if k))
