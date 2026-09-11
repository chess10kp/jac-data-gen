"""Guild alliance registry for an MMO server.

Guilds sign non-aggression pacts; the pact web is an adjacency dict of
guild tag -> list of allied guild tags. Two functions answer diplomatic
queries with a deque flood over allies.
"""
from collections import deque


def build_league(tags, pacts):
    """Adjacency dict; pacts are undirected (tag_a, tag_b) pairs."""
    net = {t: [] for t in tags}
    for a, b in pacts:
        net[a].append(b)
        net[b].append(a)
    return net


def allies_of(net, tag):
    """Every guild in ``tag``'s alliance bloc, including itself (sorted)."""
    if tag not in net:
        return []
    seen = {tag}
    queue = deque([tag])
    while queue:
        cur = queue.popleft()
        for nbr in net[cur]:
            if nbr not in seen:
                seen.add(nbr)
                queue.append(nbr)
    return sorted(seen)


def allied_with(net, tag_a, tag_b):
    """True when ``tag_b`` sits anywhere inside ``tag_a``'s pact web."""
    if tag_a not in net or tag_b not in net:
        return False
    seen = {tag_a}
    queue = deque([tag_a])
    while queue:
        cur = queue.popleft()
        if cur == tag_b:
            return True
        for nbr in net[cur]:
            if nbr not in seen:
                seen.add(nbr)
                queue.append(nbr)
    return False
