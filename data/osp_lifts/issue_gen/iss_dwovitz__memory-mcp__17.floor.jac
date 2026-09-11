"""Bounded graph-expanded memory retrieval.

dwovitz/memory-mcp#17: memories should be reachable through connected
entities, not just keyword matches, but retrieval must stay bounded -- no
unbounded graph dumps. The service resolves seed queries to canonical
entities (name or alias), traverses typed relationships within a depth
budget using an explicit visited map, collects attached memories up to a
cap, and never expands sensitive entities unless explicitly allowed.
Results are sets: matched seeds, visited entity ids, and memory texts.
"""
"""Adjacency dict of entity -> [neighbor ids].

    entities: (id, name, [aliases], sensitive) tuples; relationships are
    (left_id, right_id, rel_type) pairs materialized in both directions;
    memories are (memory_id, entity_id, text) triples.
    """
def build_memory_graph(entities: Any, relationships: Any, memories: Any) -> object {
    g = {"entities": {}, "adj": {}, "rel_types": {}, "memories": {}};
    for (eid, name, aliases, sensitive) in entities {
        g["entities"][eid] = {
            "name": name,
            "aliases": `list(aliases),
            "sensitive": sensitive
        };
        g["adj"].setdefault(eid, []);
        for alias in aliases {
            g["entities"][eid].setdefault("alias_index", {});
        }
        g["entities"][eid]["alias_list"] = `list(aliases);
    }
    for (left, right, rel_type) in relationships {
        if ((left in g["adj"]) and (right in g["adj"])) {
            g["adj"][left].append(right);
            g["adj"][right].append(left);
            g["rel_types"][(left, right)] = rel_type;
            g["rel_types"][(right, left)] = rel_type;
        }
    }
    for (mid, eid, text) in memories {
        g["memories"][mid] = {"entity": eid, "text": text};
    }
    return g;
}

"""Canonical entity ids whose name or alias equals a query (sorted)."""
def resolve_seeds(g: Any, queries: Any) -> object {
    by_name = {};
    for (eid, info) in g["entities"].items() {
        names = {info["name"]} | `set(info["alias_list"]);
        for nm in names {
            by_name.setdefault(nm, eid);
        }
    }
    hits = [];
    for q in queries {
        if ((q in by_name) and (by_name[q] not in hits)) {
            hits.append(by_name[q]);
        }
    }
    return sorted(hits);
}
"""Bounded traversal packet: (entity_ids, memory texts), both sorted.

    Traversal stops at ``max_depth`` hops from any seed; at most
    ``max_memories`` attached memories are returned; sensitive entities
    contribute nothing unless ``include_sensitive`` is set.
    """
def get_graph_context(
    g: Any,
    seed_ids: Any,
    max_depth: Any = 2,
    max_memories: Any = 10,
    include_sensitive: Any = False
) -> object {
    seen = `set();
    frontier = [
        eid
        for eid in seed_ids
        if (eid in g["entities"])
    ];
    reached = [];
    level = 0;
    while (frontier and (level <= max_depth)) {
        nxt = [];
        for cur in frontier {
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            if (g["entities"][cur]["sensitive"] and not include_sensitive) {
                continue;
            }
            reached.append(cur);
            for nb in g["adj"][cur] {
                if (nb not in seen) {
                    nxt.append(nb);
                }
            }
        }
        frontier = nxt;
        level += 1;
    }
    texts = [];
    for (mid, mem) in g["memories"].items() {
        owner = mem["entity"];
        if (owner not in seen) {
            continue;
        }
        if (g["entities"][owner]["sensitive"] and not include_sensitive) {
            continue;
        }
        texts.append(mem["text"]);
    }
    return (sorted(reached), sorted(texts)[:max_memories]);
}

