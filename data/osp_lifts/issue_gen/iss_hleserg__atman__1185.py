"""Factual-memory graph traversal.

Facts about entities carry typed relations to other entities
(``knows``, ``mentions``, ...). The memory backend keeps an in-memory
relation index and answers structural queries the vector store cannot:
who is within N hops, and are two entities connected at all. The index
is an id-keyed adjacency map walked with deque-BFS loops and visited
sets.
Ref: hleserg/atman#1185
"""
from collections import deque


def new_memory():
    return {"entities": set(), "rel": {}, "kinds": {}}


def remember(mem, entity):
    mem["entities"].add(entity)


def link(mem, src, kind, dst):
    """Directed relation ``src --kind--> dst``."""
    mem["entities"].update({src, dst})
    mem["rel"].setdefault(src, []).append(dst)
    mem["kinds"].setdefault(src, []).append(kind)


def neighbors(mem, entity, kinds=None):
    """Direct relations of ``entity``, optionally filtered by kind. Sorted."""
    out = []
    for i, dst in enumerate(mem["rel"].get(entity, [])):
        if kinds is None or mem["kinds"][entity][i] in kinds:
            out.append(dst)
    return sorted(set(out))


def related_within(mem, entity, depth, kinds=None):
    """All entities reachable from ``entity`` within ``depth`` hops over
    ``kinds`` relations (or any relation when ``kinds`` is None). Inclusive,
    sorted."""
    seen = {entity}
    frontier = [entity]
    for _ in range(depth):
        nxt = []
        for cur in frontier:
            for i, dst in enumerate(mem["rel"].get(cur, [])):
                if kinds is not None and mem["kinds"][cur][i] not in kinds:
                    continue
                if dst not in seen:
                    seen.add(dst)
                    nxt.append(dst)
        frontier = nxt
        if not frontier:
            break
    return sorted(seen)


def are_related(mem, src, dst):
    """True when ``dst`` is reachable from ``src`` over any relations."""
    seen = {src}
    queue = deque([src])
    while queue:
        cur = queue.popleft()
        for nxt in mem["rel"].get(cur, []):
            if nxt == dst:
                return True
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return False
