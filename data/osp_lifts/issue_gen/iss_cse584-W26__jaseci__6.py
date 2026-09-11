"""cse584-W26/jaseci#6 — littleX feed follow-chain reachability."""

from __future__ import annotations

from collections import deque


class FeedGraph:
    def __init__(self) -> None:
        self._users: set[str] = set()
        self._follows: dict[str, list[str]] = {}
        self._posts: dict[str, list[str]] = {}


def load_feed_graph(
    users: list[str],
    follows: list[tuple[str, str]],
    posts: list[tuple[str, str]],
) -> FeedGraph:
    g = FeedGraph()
    for u in users:
        g._users.add(u)
        g._follows.setdefault(u, [])
        g._posts.setdefault(u, [])
    for src, dst in follows:
        if src in g._users and dst in g._users:
            g._follows.setdefault(src, []).append(dst)
    for author, pid in posts:
        if author in g._users:
            g._posts.setdefault(author, []).append(pid)
    return g


def reachable_authors(graph: FeedGraph, viewer: str) -> list[str]:
    if viewer not in graph._users:
        return []
    seen: set[str] = {viewer}
    queue: deque[str] = deque([viewer])
    while queue:
        cur = queue.popleft()
        for nxt in graph._follows.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def feed_post_ids(graph: FeedGraph, viewer: str) -> list[str]:
    authors = reachable_authors(graph, viewer)
    out: list[str] = []
    for aid in authors:
        out.extend(graph._posts.get(aid, []))
    return sorted(out)


def chain_depth_ok(graph: FeedGraph, viewer: str, limit: int) -> bool:
    if viewer not in graph._users:
        return False
    depth: dict[str, int] = {viewer: 0}
    queue: deque[str] = deque([viewer])
    while queue:
        cur = queue.popleft()
        for nxt in graph._follows.get(cur, []):
            nd = depth[cur] + 1
            if nd > limit:
                return False
            if nxt not in depth or nd > depth[nxt]:
                depth[nxt] = nd
                queue.append(nxt)
    return True
