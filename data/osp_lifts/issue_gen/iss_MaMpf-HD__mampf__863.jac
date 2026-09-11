"""Event-driven cache invalidation over a model dependency graph.

MaMpf-HD/mampf#863 lifted to OSP: entities become CacheNode archetypes and
the ``consumer reads producer`` map becomes typed Feeds edges. A published
change event floods downstream through an InvalidationFlood walker whose
claim map is the explicit cycle policy; the depth-capped variant is a
level-partitioned hop walk carrying the budget as facade state. Nodes are
collected read-only during walks; staleness is committed outside them.
"""
node CacheNode {
    has entity: str;
    has cache_key: str;
}
edge Feeds {}

"""Graph handle: id resolution plus the stale-key set it owns."""
obj Graph {
    has nodes: dict[str, CacheNode];
    has stale: set;

    def resolve(entity: str) -> CacheNode | None {
        return self.nodes.get(entity);
    }
}

def build_graph(pairs: list[tuple[str, str]]) -> Graph {
    g = Graph(nodes={}, stale=set());
    for p in pairs {
        n = CacheNode(entity=p[0], cache_key=p[1]);
        root ++> n;
        g.nodes[p[0]] = n;
    }
    return g;
}

def register(g: Graph, entity: str, cache_key: str) {
    n = CacheNode(entity=entity, cache_key=cache_key);
    root ++> n;
    g.nodes[entity] = n;
}

def add_dependency(g: Graph, consumer: str, producer: str) {
    c = g.resolve(consumer);
    p = g.resolve(producer);
    if c is None or p is None {
        raise KeyError("unknown entity");
    }
    if consumer == producer {
        raise ValueError("self dependency");
    }
    # stored producer -> consumer so a change floods downstream
    p +>:Feeds:+> c;
}

"""Floods downstream along Feeds edges to consumers; once-only claims."""
walker InvalidationFlood {
    has claimed: dict[str, bool];
    has touched: list[CacheNode] = [];

    can step with CacheNode entry {
        if here.entity in self.claimed {
            skip;
        }
        self.claimed[here.entity] = True;
        self.touched.append(here);
        visit [->:Feeds:->];
    }
}

"""One-hop consumer collector used by the depth-capped walk."""
walker HopConsumers {
    has claimed: dict[str, bool];
    has found: list[CacheNode] = [];

    can step with CacheNode entry {
        cons: list[CacheNode] = [here ->:Feeds:->];
        for c in cons {
            if c.entity not in self.claimed {
                self.claimed[c.entity] = True;
                self.found.append(c);
            }
        }
    }
}

def _commit_stale(g: Graph, touched: list[CacheNode]) -> list[str] {
    keys: list[str] = [];
    for n in touched {
        keys.append(n.cache_key);
        g.stale.add(n.cache_key);
    }
    return sorted(keys);
}

def publish_change(g: Graph, entity: str) -> list[str] {
    start = g.resolve(entity);
    if start is None {
        raise KeyError("unknown entity");
    }
    w = start spawn InvalidationFlood(claimed={});
    # the source itself is not stale; drop it from the collected set
    downstream: list[CacheNode] = [];
    for n in w.touched {
        if n.entity != entity {
            downstream.append(n);
        }
    }
    return _commit_stale(g, downstream);
}

def reverse_adjacency(g: Graph) -> dict {
    # producer -> consumers reading it (public helper from the source)
    rev: dict = {};
    for entity in g.nodes.keys() {
        targets: list[CacheNode] = [g.nodes[entity] ->:Feeds:->];
        cons: list[str] = [];
        for c in targets {
            cons.append(c.entity);
        }
        if len(cons) > 0 {
            rev[entity] = cons;
        }
    }
    return rev;
}

"""Bounded sweep: stop expanding past ``depth_cap`` hops (domain rule)."""
def invalidate_all_upstream_of(g: Graph, entity: str, depth_cap: int) -> list[str] {
    start = g.resolve(entity);
    if start is None {
        raise KeyError("unknown entity");
    }
    claimed: dict[str, bool] = {entity: True};
    all_touched: list[CacheNode] = [];
    frontier: list[CacheNode] = [start];
    depth = 0;
    while len(frontier) > 0 and depth < depth_cap {
        nxt: list[CacheNode] = [];
        for f in frontier {
            w = f spawn HopConsumers(claimed=claimed, found=nxt);
            nxt = w.found;
        }
        for m in nxt {
            all_touched.append(m);
        }
        frontier = nxt;
        depth += 1;
    }
    return _commit_stale(g, all_touched);
}

def is_stale(g: Graph, entity: str) -> bool {
    n = g.resolve(entity);
    if n is None {
        return False;
    }
    return n.cache_key in g.stale;
}

def mark_fresh(g: Graph, entity: str) {
    n = g.resolve(entity);
    if n is None {
        raise KeyError("unknown entity");
    }
    g.stale.discard(n.cache_key);
}
