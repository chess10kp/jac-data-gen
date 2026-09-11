"""Caller blast radius for reusable workflow changes.

``graph`` describes who calls what across repos: ``graph["workflows"]``
maps a workflow ref to the list of refs that use it (the Uses edges),
and ``graph["repos"]`` maps a ref to the repository that owns it (the
node universe -- refs outside it do not exist). When a reusable release
workflow that thirty repos call changes, every consumer stays green
until its own next push and goes red one at a time, so the merge gate
needs the reverse direction: ``callers_of`` walks the Uses edges upward
with a depth-bounded deque BFS (visited set against cycles), and
``affected_repos`` maps the full transitive caller closure to repository
names. An unknown starting ref raises KeyError.
Ref: repobuddy/repobuddy#594
"""

from collections import deque

MAX_CALLER_HOPS = 3


def callers_of(graph, ref, max_hops=MAX_CALLER_HOPS):
    """Caller refs within ``max_hops`` Uses hops of ``ref``, sorted.

    Each caller counts at its shortest hop distance; the distance map is
    the visited set, so cyclic usage graphs cannot loop the queue.
    """
    wfs = graph["workflows"]
    repos = graph["repos"]
    if ref not in repos:
        raise KeyError(ref)
    dist = {ref: 0}
    queue = deque([ref])
    while queue:
        cur = queue.popleft()
        if dist[cur] >= max_hops:
            continue
        if cur not in wfs:
            continue
        for caller in list(wfs[cur]):
            if caller in repos and caller not in dist:
                dist[caller] = dist[cur] + 1
                queue.append(caller)
    return sorted(x for x in dist if x != ref)


def affected_repos(graph, ref):
    """Repository names of the full transitive caller closure, sorted.

    Unbounded walk over the Uses edges (the whole blast radius, however
    far it reaches); duplicate repositories collapse.
    """
    wfs = graph["workflows"]
    repos = graph["repos"]
    if ref not in repos:
        raise KeyError(ref)
    seen = {ref}
    queue = deque([ref])
    while queue:
        cur = queue.popleft()
        if cur not in wfs:
            continue
        for caller in list(wfs[cur]):
            if caller in repos and caller not in seen:
                seen.add(caller)
                queue.append(caller)
    out = {repos[c] for c in seen if c != ref}
    return sorted(out)
