"""Guard: cse584-W26/jaseci#6."""

node FeedUser {
    has uid: str;
    has post_ids: list[str] = [];
}

edge Follows {}

obj FeedGraph {
    has users: dict[str, FeedUser] = {};
}

walker AuthorReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with FeedUser entry {
        if here.uid in self.claimed { skip; }
        self.claimed[here.uid] = True;
        self.reached.append(here.uid);
        visit [->:Follows:->][?:FeedUser];
    }
}

def load_feed_graph(
    users: list[str],
    follows: list[tuple[str, str]],
    posts: list[tuple[str, str]],
) -> FeedGraph {
    g = FeedGraph();
    for u in users {
        nd = FeedUser(uid=u);
        root ++> nd;
        g.users[u] = nd;
    }
    for (src, dst) in follows {
        s = g.users.get(src, None);
        d = g.users.get(dst, None);
        if s is not None and d is not None { s +>:Follows:+> d; }
    }
    for (author, pid) in posts {
        if author in g.users {
            g.users[author].post_ids = g.users[author].post_ids + [pid];
        }
    }
    return g;
}

def reachable_authors(graph: FeedGraph, viewer: str) -> list[str] {
    nd = graph.users.get(viewer, None);
    if nd is None { return []; }
    w = nd spawn AuthorReach(claimed={}, reached=[]);
    return sorted(w.reached);
}

def feed_post_ids(graph: FeedGraph, viewer: str) -> list[str] {
    authors = reachable_authors(graph, viewer);
    out: list[str] = [];
    for aid in authors {
        nd = graph.users.get(aid, None);
        if nd is not None { out = out + nd.post_ids; }
    }
    return sorted(out);
}

def chain_depth_ok(graph: FeedGraph, viewer: str, limit: int) -> bool {
    nd = graph.users.get(viewer, None);
    if nd is None { return False; }
    depth: dict[str, int] = {viewer: 0};
    frontier: list[FeedUser] = [nd];
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        cur_depth = depth[cur.uid];
        for nxt in [cur ->:Follows:->][?:FeedUser] {
            next_depth = cur_depth + 1;
            if next_depth > limit { return False; }
            if not (nxt.uid in depth) or next_depth > depth[nxt.uid] {
                depth[nxt.uid] = next_depth;
                frontier.append(nxt);
            }
        }
    }
    return True;
}

test "feed chain reach and posts" {
    g = load_feed_graph(
        ["viewer", "a", "b", "c"],
        [("viewer", "a"), ("a", "b"), ("viewer", "c")],
        [("a", "p1"), ("b", "p2"), ("c", "p3"), ("viewer", "p0")],
    );
    assert reachable_authors(g, "viewer") == ["a", "b", "c", "viewer"];
    assert feed_post_ids(g, "viewer") == ["p0", "p1", "p2", "p3"];
    assert chain_depth_ok(g, "viewer", 2);
}

test "diamond adversarial revisit" {
    g = load_feed_graph(
        ["hub", "left", "right", "leaf"],
        [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
        [("leaf", "only")],
    );
    assert reachable_authors(g, "hub") == ["hub", "leaf", "left", "right"];
}

test "unknown viewer" {
    g = load_feed_graph(["solo"], [], []);
    assert reachable_authors(g, "missing") == [];
}
