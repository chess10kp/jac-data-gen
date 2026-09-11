"""Mentorship network: influence radius and degrees of separation.

The network is an adjacency dict of handle -> list of followed handles
(follows are directed). Influence queries run a deque BFS in level order,
one ring at a time, so hop counts stay exact.
"""
from collections import deque


def build_roster(handles, follows):
    """Adjacency dict; follows are directed (follower, followee) pairs."""
    net = {h: [] for h in handles}
    for a, b in follows:
        net[a].append(b)
    return net


def inner_circle(net, handle, radius):
    """Handles within ``radius`` follow-hops of ``handle`` (sorted)."""
    if handle not in net:
        return []
    dist = {handle: 0}
    frontier = [handle]
    depth = 0
    while frontier and depth < radius:
        depth += 1
        nxt_frontier = []
        for cur in frontier:
            for nbr in net[cur]:
                if nbr not in dist:
                    dist[nbr] = depth
                    nxt_frontier.append(nbr)
        frontier = nxt_frontier
    return sorted(dist)


def separation(net, src, dst):
    """Follow-hops from ``src`` to ``dst``; -1 if unknown or unreachable."""
    if src not in net or dst not in net:
        return -1
    dist = {src: 0}
    queue = deque([src])
    while queue:
        cur = queue.popleft()
        if cur == dst:
            return dist[cur]
        for nbr in net[cur]:
            if nbr not in dist:
                dist[nbr] = dist[cur] + 1
                queue.append(nbr)
    return -1
