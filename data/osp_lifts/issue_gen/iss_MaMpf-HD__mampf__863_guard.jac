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

test "one event invalidates the downstream closure once" {
    g = build_graph([("tag", "k_tag"), ("lecture", "k_lec"), ("course", "k_course"), ("lesson", "k_les"), ("exercise", "k_ex")]);
    add_dependency(g, "lesson", "lecture");
    add_dependency(g, "lesson", "tag");
    add_dependency(g, "course", "lecture");
    add_dependency(g, "exercise", "tag");
    assert publish_change(g, "lecture") == ["k_course", "k_les"];
    assert is_stale(g, "course") and is_stale(g, "lesson");
    assert not is_stale(g, "exercise") and not is_stale(g, "lecture");
    mark_fresh(g, "lesson");
    assert not is_stale(g, "lesson");
}

test "depth-capped sweep respects the budget" {
    g = build_graph([("root", "kr"), ("mid1", "km1"), ("mid2", "km2"), ("leaf", "kl")]);
    add_dependency(g, "mid1", "root");
    add_dependency(g, "mid2", "mid1");
    add_dependency(g, "leaf", "mid2");
    assert invalidate_all_upstream_of(g, "root", 0) == [];
    assert invalidate_all_upstream_of(g, "root", 1) == ["km1"];
    assert invalidate_all_upstream_of(g, "root", 2) == ["km1", "km2"];
    for k in ["km1", "km2"] {
        g.stale.discard(k);
    }
    assert invalidate_all_upstream_of(g, "root", 10) == ["kl", "km1", "km2"];
    rev = reverse_adjacency(g);  # producer -> its direct consumers
    assert sorted(rev.keys()) == ["mid1", "mid2", "root"], rev;
    assert rev["root"] == ["mid1"] and rev["mid1"] == ["mid2"];
    assert "leaf" not in rev;  # producers without consumers stay absent
}

test "link rejection" {
    g = build_graph([("a", "ka"), ("b", "kb")]);
    try {
        add_dependency(g, "ghost", "a");
        assert False;
    } except KeyError { assert True; }
    try {
        add_dependency(g, "a", "a");
        assert False;
    } except ValueError { assert True; }
    try {
        publish_change(g, "ghost");
        assert False;
    } except KeyError { assert True; }
}

test "imported dependency cycle terminates" {
    g = build_graph([("a", "ka"), ("b", "kb")]);
    an = g.resolve("a");
    bn = g.resolve("b");
    # a reads b AND b reads a (imported corruption)
    an +>:Feeds:+> bn;
    bn +>:Feeds:+> an;
    assert publish_change(g, "b") == ["ka"];
}
