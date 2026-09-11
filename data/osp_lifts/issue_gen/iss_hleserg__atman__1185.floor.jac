"""Factual-memory graph traversal.

Facts about entities carry typed relations to other entities
(``knows``, ``mentions``, ...). The memory backend keeps an in-memory
relation index and answers structural queries the vector store cannot:
who is within N hops, and are two entities connected at all. The index
is an id-keyed adjacency map walked with deque-BFS loops and visited
sets.
Ref: hleserg/atman#1185
"""
import from collections { deque }
def new_memory() -> object {
    return {"entities": `set(), "rel": {}, "kinds": {}};
}
def remember(mem: Any, entity: Any) -> object {
    mem["entities"].add(entity);
}
"""Directed relation ``src --kind--> dst``."""
def link(mem: Any, src: Any, kind: Any, dst: Any) -> object {
    mem["entities"].update({src, dst});
    mem["rel"].setdefault(src, []).append(dst);
    mem["kinds"].setdefault(src, []).append(kind);
}
"""Direct relations of ``entity``, optionally filtered by kind. Sorted."""
def neighbors(mem: Any, entity: Any, kinds: Any = None) -> object {
    out = [];
    for (i, dst) in enumerate(mem["rel"].get(entity, [])) {
        if ((kinds is None) or (mem["kinds"][entity][i] in kinds)) {
            out.append(dst);
        }
    }
    return sorted(`set(out));
}
"""All entities reachable from ``entity`` within ``depth`` hops over
    ``kinds`` relations (or any relation when ``kinds`` is None). Inclusive,
    sorted."""
def related_within(mem: Any, entity: Any, depth: Any, kinds: Any = None) -> object {
    seen = {entity};
    frontier = [entity];
    for _ in range(depth) {
        nxt = [];
        for cur in frontier {
            for (i, dst) in enumerate(mem["rel"].get(cur, [])) {
                if ((kinds is not None) and (mem["kinds"][cur][i] not in kinds)) {
                    continue;
                }
                if (dst not in seen) {
                    seen.add(dst);
                    nxt.append(dst);
                }
            }
        }
        frontier = nxt;
        if not frontier {
            break;
        }
    }
    return sorted(seen);
}

"""True when ``dst`` is reachable from ``src`` over any relations."""
def are_related(mem: Any, src: Any, dst: Any) -> object {
    seen = {src};
    queue = deque([src]);
    while queue {
        cur = queue.popleft();
        for nxt in mem["rel"].get(cur, []) {
            if (nxt == dst) {
                return True;
            }
            if (nxt not in seen) {
                seen.add(nxt);
                queue.append(nxt);
            }
        }
    }
    return False;
}

