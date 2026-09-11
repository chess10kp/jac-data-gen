"""Cluster broadcast planner lifted to OSP.

Servers become Host nodes; links become undirected FiberLink edges. The
level-by-level push becomes level-partitioned walker expansion, so each
hostname pins at its exact hop count. The hops map is the explicit cycle
policy — jac walkers never dedupe on their own.
"""
node Host {
    has name: str;
}
edge FiberLink {}

"""Loader handle: hostnames resolve through this lookup map."""
obj Cluster {
    has hosts: dict[str, Host];

    def resolve(name: str) -> Host | None {
        return self.hosts.get(name);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def build_cluster(hosts: list[str], links: list[tuple[str, str]]) -> Cluster {
    net = Cluster(hosts={});
    for h in hosts {
        n = Host(name=h);
        root ++> n;
        net.hosts[h] = n;
    }
    for (a, b) in links {
        ha = net.hosts[a];
        hb = net.hosts[b];
        ha +>:FiberLink:+> hb;
        hb +>:FiberLink:+> ha;
    }
    return net;
}

walker HopFan {
    has hops: dict[str, int] = {};
    has depth: int = 1;
    has fresh: list[Host] = [];
    has seeding: bool = True;

    can step with Host entry {
        # Only the seed expands this round; freshly claimed hosts wait for
        # the next round so every hop count stays exact.
        if self.seeding {
            self.seeding = False;
            visit [->:FiberLink:->] else { disengage; }
        } else {
            if here.name in self.hops {
                skip;
            }
            self.hops[here.name] = self.depth;
            self.fresh.append(here);
        }
    }
}

"""Run BFS rounds from ``origin_node``; returns hostname -> exact hops."""
def _fan_out(origin_node: Host, origin_name: str) -> dict[str, int] {
    hops: dict[str, int] = {};
    hops[origin_name] = 0;
    frontier: list[Host] = [origin_node];
    depth = 0;
    while len(frontier) > 0 {
        depth += 1;
        fresh: list[Host] = [];
        for seed in frontier {
            _ = seed spawn HopFan(hops=hops, depth=depth, fresh=fresh);
        }
        frontier = fresh;
    }
    return hops;
}

"""hostname -> hop count at which it receives the push."""
def broadcast_plan(net: Cluster, origin: str) -> dict[str, int] {
    start = net.resolve(origin);
    if start is None {
        return {};
    }
    return _fan_out(start, origin);
}

"""Hops until the whole reachable cluster is updated (0 if alone, -1
when the origin is unknown)."""
def propagation_time(net: Cluster, origin: str) -> int {
    start = net.resolve(origin);
    if start is None {
        return -1;
    }
    plan = _fan_out(start, origin);
    worst = 0;
    for (h, d) in plan.items() {
        if d > worst {
            worst = d;
        }
    }
    return worst;
}
