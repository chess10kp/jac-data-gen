"""Multi-hop reasoning over a memory relationship graph.

The memory store keeps memories as a flat list plus a link list of
``(from, to, kind, strength)`` records with kinds ``references``,
``contradicts``, ``builds_on``, ``caused_by``, ``similar_to`` and
``part_of``. The knowledge-graph integration needs to discover
relationships and reason across hops ("memories related to memories
about X") and to detect contradictions, so the flat store grows a
hand-rolled adjacency dict and a deque BFS: ``related_within`` collects
every memory within ``hops`` links of a starting memory (links navigated
in both directions -- a relationship relates both memories), and
``contradiction_pairs`` lists the canonical contradictory pairs.
Unknown memory ids inside links are skipped; an unknown starting id
raises KeyError.
Ref: DollhouseMCP/mcp-server#337
"""

from collections import deque


def related_within(store, mid, hops=2):
    """Memory ids within ``hops`` links of ``mid`` (itself excluded), sorted.

    Breadth-first over the undirected view of the link list; each memory
    counts at its shortest link distance, so a memory reachable through
    any chain of at most ``hops`` links is included, and link cycles
    cannot loop the queue (the distance map is the visited set).
    """
    adj = {}
    for frm, to, kind, strength in store["links"]:
        if frm in store["memories"] and to in store["memories"]:
            adj.setdefault(frm, []).append(to)
            adj.setdefault(to, []).append(frm)
    if mid not in store["memories"]:
        raise KeyError(mid)
    dist = {mid: 0}
    queue = deque([mid])
    while queue:
        cur = queue.popleft()
        if dist[cur] >= hops:
            continue
        if cur not in adj:
            continue
        for nbr in list(adj[cur]):
            if nbr not in dist:
                dist[nbr] = dist[cur] + 1
                queue.append(nbr)
    return sorted(x for x in dist if x != mid)


def contradiction_pairs(store):
    """Canonical contradictory pairs ``[[a, b], ...]`` with a < b, sorted.

    One entry per distinct ``contradicts`` link, direction ignored.
    """
    pairs = set()
    for frm, to, kind, strength in store["links"]:
        if kind != "contradicts":
            continue
        if frm not in store["memories"] or to not in store["memories"]:
            continue
        pairs.add((frm, to) if frm < to else (to, frm))
    return sorted([a, b] for a, b in pairs)
