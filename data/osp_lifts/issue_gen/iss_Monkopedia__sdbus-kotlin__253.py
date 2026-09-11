"""Gradle CI cold-resolve planner. Source: Monkopedia/sdbus-kotlin#253."""

from __future__ import annotations

from collections import deque


def resolve_with_cache(
    artifact: str,
    deps: dict[str, list[str]],
    cache: dict[str, str],
) -> tuple[list[str], list[str]]:
    adj: dict[str, list[str]] = {k: list(v) for k, v in deps.items()}
    for k in deps:
        adj.setdefault(k, [])
    visited: set[str] = set()
    queue: deque[str] = deque([artifact])
    hits: list[str] = []
    misses: list[str] = []
    while queue:
        cur = queue.popleft()
        if cur in visited:
            continue
        visited.add(cur)
        if cur in cache:
            hits.append(cur)
        else:
            misses.append(cur)
        for nxt in adj.get(cur, []):
            if nxt not in visited:
                queue.append(nxt)
    return (sorted(hits), sorted(misses))


def ancestor_chain(job: str, parent: dict[str, str]) -> list[str]:
    memo: dict[str, list[str]] = {}

    def walk(n: str) -> list[str]:
        if n in memo:
            return memo[n]
        chain: list[str] = []
        cur = n
        while cur in parent:
            cur = parent[cur]
            chain.append(cur)
        memo[n] = chain
        return chain

    return walk(job)


def uncached_misses(artifacts: list[str], cache: set[str]) -> list[str]:
    out: list[str] = []
    for art in artifacts:
        if art not in cache:
            out.append(art)
    return sorted(set(out))
