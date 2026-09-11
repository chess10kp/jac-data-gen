"""Neighborhood portal friend-circle queries.

Members of a housing co-op register on the portal; mutual friendships form an
undirected graph keyed by member id. A "friend circle" is a connected
component of that graph. Traversal is a classic adjacency-dict BFS with a
deque frontier and a visited set.
"""
from collections import deque


def build_network(members, friendships):
    """Adjacency dict: member id -> list of friend ids."""
    graph = {m: [] for m in members}
    for a, b in friendships:
        graph[a].append(b)
        graph[b].append(a)
    return graph


def circle_of(graph, member):
    """All ids in the friend circle containing ``member`` (sorted).

    Unknown ids yield an empty circle.
    """
    if member not in graph:
        return []
    seen = {member}
    queue = deque([member])
    while queue:
        cur = queue.popleft()
        for nbr in graph[cur]:
            if nbr not in seen:
                seen.add(nbr)
                queue.append(nbr)
    return sorted(seen)


def circle_count(graph):
    """Number of disjoint friend circles in the network."""
    seen = set()
    count = 0
    for m in graph:
        if m in seen:
            continue
        count += 1
        seen.add(m)
        queue = deque([m])
        while queue:
            cur = queue.popleft()
            for nbr in graph[cur]:
                if nbr not in seen:
                    seen.add(nbr)
                    queue.append(nbr)
    return count
