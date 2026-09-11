"""Office buddy matcher: mutual ties and second-degree suggestions.

Coworkers are stored in an adjacency dict of nickname -> list of desk
neighbors (ties are undirected). Matching runs short deque walks over the
dict: one hop for mutuality, two hops for suggestions.
"""
from collections import deque


def build_office(nicknames, desk_ties):
    """Adjacency dict; desk_ties are undirected (a, b) pairs."""
    office = {n: [] for n in nicknames}
    for a, b in desk_ties:
        office[a].append(b)
        office[b].append(a)
    return office


def _within(office, who, hops):
    """Nickname -> distance for everyone within ``hops`` desk-hops of
    ``who`` (deque level walk, exact distances)."""
    if who not in office:
        return {}
    dist = {who: 0}
    frontier = [who]
    depth = 0
    while frontier and depth < hops:
        depth += 1
        nxt_frontier = []
        for cur in frontier:
            for nbr in office[cur]:
                if nbr not in dist:
                    dist[nbr] = depth
                    nxt_frontier.append(nbr)
        frontier = nxt_frontier
    del dist[who]
    return dist


def mutual_buddies(office, a, b):
    """Shared direct desk neighbors of ``a`` and ``b`` (sorted)."""
    common = set(_within(office, a, 1)) & set(_within(office, b, 1))
    return sorted(common)


def suggestions(office, who):
    """Second-degree neighbors minus self and direct ties (sorted).

    A candidate counts once even when reachable through several buddies,
    and someone already at a desk next door is never suggested.
    """
    near = _within(office, who, 2)
    return sorted(nick for nick, d in near.items() if d == 2)
