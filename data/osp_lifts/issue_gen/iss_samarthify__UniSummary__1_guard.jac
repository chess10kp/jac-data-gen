"""samarthify/UniSummary#1 — Week-3 graph traversals (BFS/DFS) over topic adjacency."""

node Topic {
    has cid: str;
}

edge StudyLink {}

walker BfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Topic entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        pending: list[Topic] = [];
        for ch in [here ->:StudyLink:->][?:Topic] {
            if ch.cid not in self.claimed {
                pending.append(ch);
            }
        }
        if pending {
            visit pending;
        } else {
            disengage;
        }
    }
}

walker DfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Topic entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        kids: list[Topic] = [];
        for ch in [here ->:StudyLink:->][?:Topic] {
            if ch.cid not in self.claimed {
                kids.append(ch);
            }
        }
        rev: list[Topic] = [];
        idx: int = len(kids) - 1;
        while idx >= 0 {
            rev.append(kids[idx]);
            idx -= 1;
        }
        if rev {
            for ch in rev {
                visit :0: [ch];
            }
        } else {
            disengage;
        }
    }
}

walker RoadmapDemo {
    can go with Root entry {
        demo_edges: list[tuple[str, str]] = [
            ("graphs", "dfs"),
            ("graphs", "bfs"),
            ("dfs", "recursion")
        ];
        g = build_topic_graph(demo_edges);
        b = bfs_topics(g, "graphs");
        print(len(b));
        disengage;
    }
}

def build_topic_graph(edges: list[tuple[str, str]]) -> dict[str, Topic] {
    store: dict[str, Topic] = {};
    for pair in edges {
        a: str = pair[0];
        b: str = pair[1];
        if a not in store {
            nd_a = Topic(cid=a);
            store[a] = nd_a;
            root ++> nd_a;
        }
        if b not in store {
            nd_b = Topic(cid=b);
            store[b] = nd_b;
            root ++> nd_b;
        }
        src = store[a];
        dst = store[b];
        src +>:StudyLink:+> dst;
    }
    return store;
}

def bfs_topics(graph: dict[str, Topic], start: str) -> list[str] {
    if start not in graph {
        return [];
    }
    st = graph[start];
    w = st spawn BfsWalker(claimed={}, order=[]);
    return w.order;
}

def dfs_topics(graph: dict[str, Topic], start: str) -> list[str] {
    if start not in graph {
        return [];
    }
    st = graph[start];
    w = st spawn DfsWalker(claimed={}, order=[]);
    return w.order;
}

def count_study_components(graph: dict[str, Topic]) -> int {
    global_claimed: dict[str, bool] = {};
    ids: list[str] = [];
    for cid in graph {
        ids.append(cid);
    }
    sorted_ids: list[str] = sorted(ids);
    total: int = 0;
    for cid in sorted_ids {
        if cid not in global_claimed {
            st = graph[cid];
            w = st spawn BfsWalker(claimed=global_claimed, order=[]);
            for k in w.claimed {
                global_claimed[k] = True;
            }
            total += 1;
        }
    }
    return total;
}

with entry {
    root spawn RoadmapDemo();
}

"""samarthify/UniSummary#1 — Week-3 graph traversals (BFS/DFS) over topic adjacency."""

node Topic {
    has cid: str;
}

edge StudyLink {}

walker BfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Topic entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        pending: list[Topic] = [];
        for ch in [here ->:StudyLink:->][?:Topic] {
            if ch.cid not in self.claimed {
                pending.append(ch);
            }
        }
        if pending {
            visit pending;
        } else {
            disengage;
        }
    }
}

walker DfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Topic entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        kids: list[Topic] = [];
        for ch in [here ->:StudyLink:->][?:Topic] {
            if ch.cid not in self.claimed {
                kids.append(ch);
            }
        }
        rev: list[Topic] = [];
        idx: int = len(kids) - 1;
        while idx >= 0 {
            rev.append(kids[idx]);
            idx -= 1;
        }
        if rev {
            for ch in rev {
                visit :0: [ch];
            }
        } else {
            disengage;
        }
    }
}

walker RoadmapDemo {
    can go with Root entry {
        demo_edges: list[tuple[str, str]] = [
            ("graphs", "dfs"),
            ("graphs", "bfs"),
            ("dfs", "recursion")
        ];
        g = build_topic_graph(demo_edges);
        b = bfs_topics(g, "graphs");
        print(len(b));
        disengage;
    }
}

def build_topic_graph(edges: list[tuple[str, str]]) -> dict[str, Topic] {
    store: dict[str, Topic] = {};
    for pair in edges {
        a: str = pair[0];
        b: str = pair[1];
        if a not in store {
            nd_a = Topic(cid=a);
            store[a] = nd_a;
            root ++> nd_a;
        }
        if b not in store {
            nd_b = Topic(cid=b);
            store[b] = nd_b;
            root ++> nd_b;
        }
        src = store[a];
        dst = store[b];
        src +>:StudyLink:+> dst;
    }
    return store;
}

def bfs_topics(graph: dict[str, Topic], start: str) -> list[str] {
    if start not in graph {
        return [];
    }
    st = graph[start];
    w = st spawn BfsWalker(claimed={}, order=[]);
    return w.order;
}

def dfs_topics(graph: dict[str, Topic], start: str) -> list[str] {
    if start not in graph {
        return [];
    }
    st = graph[start];
    w = st spawn DfsWalker(claimed={}, order=[]);
    return w.order;
}

def count_study_components(graph: dict[str, Topic]) -> int {
    global_claimed: dict[str, bool] = {};
    ids: list[str] = [];
    for cid in graph {
        ids.append(cid);
    }
    sorted_ids: list[str] = sorted(ids);
    total: int = 0;
    for cid in sorted_ids {
        if cid not in global_claimed {
            st = graph[cid];
            w = st spawn BfsWalker(claimed=global_claimed, order=[]);
            for k in w.claimed {
                global_claimed[k] = True;
            }
            total += 1;
        }
    }
    return total;
}

with entry {
    root spawn RoadmapDemo();
}

def _fixture_edges() -> list[tuple[str, str]] {
    return [
        ("graphs", "dfs"),
        ("graphs", "bfs"),
        ("dfs", "recursion")
    ];
}

test "bfs_topics_reachable_order" {
    g = build_topic_graph(_fixture_edges());
    got = bfs_topics(g, "graphs");
    assert got == ["graphs", "dfs", "bfs", "recursion"];
}

test "dfs_topics_reachable_order" {
    g = build_topic_graph(_fixture_edges());
    got = dfs_topics(g, "graphs");
    assert got == ["graphs", "dfs", "recursion", "bfs"];
}

test "bfs_unknown_start_empty" {
    g = build_topic_graph(_fixture_edges());
    got = bfs_topics(g, "missing");
    assert got == [];
}

test "dfs_unknown_start_empty" {
    g = build_topic_graph(_fixture_edges());
    got = dfs_topics(g, "missing");
    assert got == [];
}

test "count_study_components_single" {
    g = build_topic_graph(_fixture_edges());
    assert count_study_components(g) == 1;
}

test "count_study_components_isolated" {
    edges: list[tuple[str, str]] = [("a", "b"), ("c", "d")];
    g = build_topic_graph(edges);
    assert count_study_components(g) == 2;
}
