"""Focused crawler: pages reachable within a link budget.

The crawler keeps an explicit frontier of ``(url, depth)`` pairs in a deque
and a visited set; it never follows a link past ``max_depth`` hops.
"""
from collections import deque


def build_web(urls, links):
    """Adjacency dict: url -> list of (target_url, anchor_text)."""
    web = {u: [] for u in urls}
    for src, dst, anchor in links:
        web[src].append((dst, anchor))
    return web


def crawl(web, start_url, max_depth):
    """All urls reachable from ``start_url`` within ``max_depth`` hops."""
    if start_url not in web:
        return []
    seen = {start_url}
    queue = deque([(start_url, 0)])
    while queue:
        cur, depth = queue.popleft()
        if depth >= max_depth:
            continue
        for nxt, _anchor in web[cur]:
            if nxt not in seen:
                seen.add(nxt)
                queue.append((nxt, depth + 1))
    return sorted(seen)


def frontier_at_limit(web, start_url, max_depth):
    """Urls sitting at exactly ``max_depth`` hops from the start."""
    if start_url not in web:
        return []
    dist = {start_url: 0}
    queue = deque([(start_url, 0)])
    while queue:
        cur, depth = queue.popleft()
        if depth >= max_depth:
            continue
        for nxt, _anchor in web[cur]:
            if nxt not in dist:
                dist[nxt] = depth + 1
                queue.append((nxt, depth + 1))
    return sorted(u for u, d in dist.items() if d == max_depth)
