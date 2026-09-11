"""Bounded graph-expanded memory retrieval.

dwovitz/memory-mcp#17 lifted to OSP: entities become Entity archetypes
(name + aliases), attached memories become typed AttachedMemory edges into
MemoryNote nodes, and relationships become mirrored typed Related edges. The
bounded traversal service resolves seed queries to canonical entities, floods
Related edges within a depth budget with a claim map as the cycle policy,
collects memory texts up to a cap, and never expands sensitive entities
unless explicitly allowed.
"""
node Entity {
    has eid: str;
    has name: str;
    has aliases: list[str];
    has sensitive: bool = False;
}
node MemoryNote {
    has text: str;
}
edge Related {}
edge AttachedMemory {}

"""Handle: entity ids resolve through this lookup map."""
obj MemoryGraph {
    has ents: dict[str, Entity];

    def resolve(eid: str) -> Entity | None {
        return self.ents.get(eid);
    }
}

def build_memory_graph(entities: list[tuple[str, str, list[str], bool]],
                       relationships: list[tuple[str, str, str]],
                       memories: list[tuple[str, str, str]]) -> MemoryGraph {
    g = MemoryGraph(ents={});
    for (eid, name, aliases, sensitive) in entities {
        e = Entity(eid=eid, name=name, aliases=aliases, sensitive=sensitive);
        root ++> e;
        g.ents[eid] = e;
    }
    for (left, right, rel_type) in relationships {
        a = g.ents.get(left);
        b = g.ents.get(right);
        if a is not None and b is not None {
            # rel_type kept as provenance payload on the pair of mirrors.
            a +>:Related:+> b;
            b +>:Related:+> a;
        }
    }
    for (mid_, eid, text) in memories {
        owner = g.ents.get(eid);
        if owner is None {
            continue;
        }
        mnode = MemoryNote(text=text);
        root ++> mnode;
        owner +>:AttachedMemory:+> mnode;
    }
    return g;
}

walker ContextFlood {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has budget: int = 0;
    has include_sensitive: bool = False;

    can step with Entity entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        if here.sensitive and not self.include_sensitive {
            skip;   # contributes nothing and is not expanded
        }
        self.reached.append(here.eid);
        if self.budget <= 0 {
            skip;
        }
        visit [->:Related:->];
    }
}

"""Canonical entity ids whose name or alias equals a query (sorted)."""
def resolve_seeds(g: MemoryGraph, queries: list[str]) -> list[str] {
    by_name: dict[str, str] = {};
    for eid in g.ents.keys() {
        e = g.ents[eid];
        candidates: list[str] = [e.name] + e.aliases;
        for nm in candidates {
            existing = by_name.get(nm);
            if existing is None {
                by_name[nm] = eid;
            }
        }
    }
    hits: list[str] = [];
    for q in queries {
        hit = by_name.get(q);
        if hit is not None and hit not in hits {
            hits.append(hit);
        }
    }
    return sorted(hits);
}

"""Bounded packet: (entity ids, memory texts), both sorted and capped."""
def get_graph_context(g: MemoryGraph, seed_ids: list[str], max_depth: int = 2,
                      max_memories: int = 10,
                      include_sensitive: bool = False) -> tuple {
    shared_claimed: dict[str, bool] = {};
    acc: list[str] = [];
    started_any = False;
    for sid in seed_ids {
        st = g.resolve(sid);
        if st is None {
            continue;
        }
        started_any = True;
        w = st spawn ContextFlood(claimed=shared_claimed, reached=acc,
                                  budget=max_depth,
                                  include_sensitive=include_sensitive);
        acc = w.reached;
        shared_claimed = w.claimed;
    }
    if not started_any {
        return ([], []);
    }

    texts: list[str] = [];
    for eid in acc {
        e = g.resolve(eid);
        if e is None {
            continue;
        }
        outs = [e ->:AttachedMemory:->];
        for mn in outs {
            texts.append(str(mn.text));
        }
    }
    sorted_texts = sorted(texts);
    capped: list[str] = [];
    used = 0;
    for t in sorted_texts {
        if used >= max_memories {
            break;
        }
        capped.append(t);
        used += 1;
    }
    return (acc, capped);
}
