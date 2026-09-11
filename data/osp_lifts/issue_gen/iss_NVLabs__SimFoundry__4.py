"""Scene-reconstruction support ordering.

Objects recovered from a video scene rest on one another; removing an
object drops everything transitively resting on it, while a removal plan
needs the transitive supporters of each object. The support graph is
hand-built as id-keyed adjacency dicts and unwound with deque-BFS loops
and visited sets. With overlapping masks the inference can produce
mutual-support cycles (A rests on B *and* B on A); an earlier revision
of this unwind had no visited set and spun forever around such cycles.
Ref: NVlabs/SimFoundry#4
"""
from collections import deque


def load_scene(items, rests_on):
    """Build the support maps.

    ``items``: object ids. ``rests_on``: ``(item, supporter)`` pairs.
    Returns ``{"holds": sup -> dependents, "rests": item -> supporters}``.
    """
    holds = {i: [] for i in items}
    rests = {i: [] for i in items}
    for item, sup in rests_on:
        holds[sup].append(item)
        rests[item].append(sup)
    return {"holds": holds, "rests": rests}


def fallout_of(scene, item):
    """Everything that falls when ``item`` is removed, itself included."""
    seen = {item}
    queue = deque([item])
    while queue:
        cur = queue.popleft()
        for nxt in scene["holds"].get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def supporters_of(scene, item):
    """Transitive closure of everything holding ``item`` up, itself included."""
    seen = {item}
    queue = deque([item])
    while queue:
        cur = queue.popleft()
        for nxt in scene["rests"].get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def is_supported_by(scene, item, candidate):
    """True when ``candidate`` transitively supports ``item``."""
    if item == candidate:
        return False
    seen = {item}
    queue = deque([item])
    while queue:
        cur = queue.popleft()
        for nxt in scene["rests"].get(cur, []):
            if nxt == candidate:
                return True
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return False
