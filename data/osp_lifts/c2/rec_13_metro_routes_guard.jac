"""Transit planner lifted to OSP.

Stations become nodes, connections become undirected Track edges carrying
the line payload. Reachability is a flooding walker; fewest-stop routes
reproduce BFS level order via level-partitioned walker expansion, with the
dist map as the explicit cycle policy.
"""
node Station {
    has code: str;
}
edge Track {
    has line: str;
}

"""Loader handle: station codes resolve through this lookup map."""
obj MetroNet {
    has stops: dict[str, Station];

    def resolve(code: str) -> Station | None {
        return self.stops.get(code);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def build_metro(stations: list[str], connections: list[tuple[str, str, str]]) -> MetroNet {
    net = MetroNet(stops={});
    for s in stations {
        n = Station(code=s);
        root ++> n;
        net.stops[s] = n;
    }
    for (a, b, line) in connections {
        na = net.stops[a];
        nb = net.stops[b];
        na +>:Track(line=line):+> nb;
        nb +>:Track(line=line):+> na;
    }
    return net;
}

walker Flood {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can step with Station entry {
        if here.code in self.claimed {
            skip;
        }
        self.claimed[here.code] = True;
        self.names.append(here.code);
        visit [->:Track:->] else { disengage; }
    }
}

walker HopExpand {
    has dist: dict[str, int] = {};
    has depth: int = 0;
    has fresh: list[Station] = [];
    has seeding: bool = True;

    can step with Station entry {
        if self.seeding {
            self.seeding = False;
            visit [->:Track:->] else { disengage; }
        } else {
            if here.code in self.dist {
                skip;
            }
            self.dist[here.code] = self.depth;
            self.fresh.append(here);
        }
    }
}

"""Every station reachable from ``station``, including itself (sorted)."""
def reachable(net: MetroNet, station: str) -> list[str] {
    start = net.resolve(station);
    if start is None {
        return [];
    }
    w = start spawn Flood();
    return sorted(w.names);
}

"""Fewest hops between two stations; -1 if unknown or unreachable."""
def min_stops(net: MetroNet, src: str, dst: str) -> int {
    start = net.resolve(src);
    if start is None {
        return -1;
    }
    if net.resolve(dst) is None {
        return -1;
    }
    dist: dict[str, int] = {};
    dist[src] = 0;
    if src == dst {
        return 0;
    }
    frontier: list[Station] = [start];
    depth = 0;
    while len(frontier) > 0 {
        depth += 1;
        fresh: list[Station] = [];
        for seed in frontier {
            _ = seed spawn HopExpand(dist=dist, depth=depth, fresh=fresh);
        }
        frontier = fresh;
        if dst in dist {
            return dist[dst];
        }
    }
    return -1;
}

test "reachability multiset" {
    net = build_metro(["kings", "cross", "oxford", "bank", "euston"], [("kings", "cross", "northern"), ("cross", "oxford", "central"), ("oxford", "bank", "central"), ("euston", "kings", "victoria")]);
    assert reachable(net, "kings") == ["bank", "cross", "euston", "kings", "oxford"];
}

test "min stops pins hop counts" {
    net = build_metro(["a", "b", "c", "d"], [("a", "b", "l1"), ("b", "c", "l1"), ("c", "d", "l2")]);
    assert min_stops(net, "a", "a") == 0;
    assert min_stops(net, "a", "b") == 1;
    assert min_stops(net, "a", "d") == 3;
}

test "unreachable island returns -1" {
    net = build_metro(["a", "b", "p", "q"], [("a", "b", "l1"), ("p", "q", "l2")]);
    assert min_stops(net, "a", "q") == -1;
}

test "unknown stations" {
    net = build_metro(["a"], []);
    assert reachable(net, "ghost") == [];
    assert min_stops(net, "ghost", "a") == -1;
    assert min_stops(net, "a", "ghost") == -1;
}

test "diamond revisit tolerated in reachability" {
    net = build_metro(["a", "b", "c", "d"], [("a", "b", "l1"), ("a", "c", "l1"), ("b", "d", "l1"), ("c", "d", "l1")]);
    assert reachable(net, "a") == ["a", "b", "c", "d"];
}
