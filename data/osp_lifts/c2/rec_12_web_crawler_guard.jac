"""Focused crawler lifted to OSP.

Pages become nodes, links become directed LinkTo edges carrying the
anchor payload. The (url, depth) deque becomes level-partitioned walker
expansion: one HopExpand walker per frontier page per round claims each
page at its exact hop depth. The dist map doubles as the explicit cycle
policy — jac 0.36.1 walkers never dedupe on their own.
"""
node Page {
    has url: str;
}
edge LinkTo {
    has anchor: str;
}

"""Loader handle: url-string parameters resolve through this lookup map."""
obj Web {
    has pages: dict[str, Page];

    def resolve(url: str) -> Page | None {
        return self.pages.get(url);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def build_web(urls: list[str], links: list[tuple[str, str, str]]) -> Web {
    net = Web(pages={});
    for u in urls {
        p = Page(url=u);
        root ++> p;
        net.pages[u] = p;
    }
    for (src, dst, anchor) in links {
        a = net.pages[src];
        b = net.pages[dst];
        a +>:LinkTo(anchor=anchor):+> b;
    }
    return net;
}

walker HopExpand {
    has dist: dict[str, int] = {};
    has depth: int = 0;
    has fresh: list[Page] = [];
    has seeding: bool = True;

    can step with Page entry {
        if self.seeding {
            self.seeding = False;
            visit [->:LinkTo:->] else { disengage; }
        } else {
            if here.url in self.dist {
                skip;
            }
            self.dist[here.url] = self.depth;
            self.fresh.append(here);
        }
    }
}

"""Expand one BFS level from every page in ``frontier`` into ``dist``."""
def _expand_level(frontier: list[Page], dist: dict[str, int], depth: int) -> list[Page] {
    fresh: list[Page] = [];
    for seed in frontier {
        _ = seed spawn HopExpand(dist=dist, depth=depth, fresh=fresh);
    }
    return fresh;
}

"""All urls reachable from ``start_url`` within ``max_depth`` hops."""
def crawl(net: Web, start_url: str, max_depth: int) -> list[str] {
    start = net.resolve(start_url);
    if start is None {
        return [];
    }
    dist: dict[str, int] = {};
    dist[start_url] = 0;
    frontier: list[Page] = [start];
    depth = 0;
    while len(frontier) > 0 and depth < max_depth {
        depth += 1;
        frontier = _expand_level(frontier, dist, depth);
    }
    return sorted(dist);
}

"""Urls sitting at exactly ``max_depth`` hops from the start."""
def frontier_at_limit(net: Web, start_url: str, max_depth: int) -> list[str] {
    start = net.resolve(start_url);
    if start is None {
        return [];
    }
    dist: dict[str, int] = {};
    dist[start_url] = 0;
    frontier: list[Page] = [start];
    depth = 0;
    while len(frontier) > 0 {
        depth += 1;
        frontier = _expand_level(frontier, dist, depth);
    }
    out: list[str] = [];
    for (u, d) in dist.items() {
        if d == max_depth {
            out.append(u);
        }
    }
    return sorted(out);
}

test "crawl respects depth budget" {
    net = build_web(["home", "/a", "/b", "/c", "/d"], [("home", "/a", "read"), ("/a", "/b", "next"), ("/b", "/c", "next"), ("/c", "/d", "next"), ("/c", "/a", "back")]);
    assert crawl(net, "home", 0) == ["home"];
    assert crawl(net, "home", 2) == ["/a", "/b", "home"];
    assert crawl(net, "home", 10) == ["/a", "/b", "/c", "/d", "home"];
}

test "frontier pins exact hop levels" {
    net = build_web(["home", "/a", "/b", "/c"], [("home", "/a", "r"), ("/a", "/b", "n"), ("/b", "/c", "n")]);
    assert frontier_at_limit(net, "home", 0) == ["home"];
    assert frontier_at_limit(net, "home", 1) == ["/a"];
    assert frontier_at_limit(net, "home", 3) == ["/c"];
}

test "unknown start url is empty" {
    net = build_web(["home"], []);
    assert crawl(net, "missing", 3) == [];
    assert frontier_at_limit(net, "missing", 2) == [];
}

test "pure link cycle terminates" {
    net = build_web(["x", "y"], [("x", "y", "l"), ("y", "x", "l")]);
    assert crawl(net, "x", 99) == ["x", "y"];
}

test "diamond revisit does not truncate crawl" {
    net = build_web(["a", "b", "c", "d"], [("a", "b", "l"), ("a", "c", "l"), ("b", "d", "l"), ("c", "d", "l")]);
    assert crawl(net, "a", 10) == ["a", "b", "c", "d"];
}
