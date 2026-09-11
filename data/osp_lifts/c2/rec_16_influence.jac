"""Mentorship network lifted to OSP.

Handles become Person nodes; follows become directed Follows edges. The
level-order deque BFS becomes level-partitioned walker expansion: each
round spawns one RingExpand walker per frontier node, claiming every page
at its exact hop depth. The dist map is the explicit cycle policy for the
follow-ring cycles the network allows.
"""
node Person {
    has handle: str;
}
edge Follows {}

"""Loader handle: handle strings resolve through this lookup map."""
obj Roster {
    has people: dict[str, Person];

    def resolve(handle: str) -> Person | None {
        return self.people.get(handle);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def build_roster(handles: list[str], follows: list[tuple[str, str]]) -> Roster {
    net = Roster(people={});
    for h in handles {
        p = Person(handle=h);
        root ++> p;
        net.people[h] = p;
    }
    for (a, b) in follows {
        pa = net.people[a];
        pb = net.people[b];
        pa +>:Follows:+> pb;
    }
    return net;
}

walker RingExpand {
    has dist: dict[str, int] = {};
    has depth: int = 0;
    has fresh: list[Person] = [];
    has seeding: bool = True;

    can step with Person entry {
        if self.seeding {
            self.seeding = False;
            visit [->:Follows:->] else { disengage; }
        } else {
            if here.handle in self.dist {
                skip;
            }
            self.dist[here.handle] = self.depth;
            self.fresh.append(here);
        }
    }
}

"""Expand one hop from every person in ``frontier`` into ``dist``."""
def _expand(frontier: list[Person], dist: dict[str, int], depth: int) -> list[Person] {
    fresh: list[Person] = [];
    for seed in frontier {
        _ = seed spawn RingExpand(dist=dist, depth=depth, fresh=fresh);
    }
    return fresh;
}

"""Handles within ``radius`` follow-hops of ``handle`` (sorted)."""
def inner_circle(net: Roster, handle: str, radius: int) -> list[str] {
    start = net.resolve(handle);
    if start is None {
        return [];
    }
    dist: dict[str, int] = {};
    dist[handle] = 0;
    frontier: list[Person] = [start];
    depth = 0;
    while len(frontier) > 0 and depth < radius {
        depth += 1;
        frontier = _expand(frontier, dist, depth);
    }
    return sorted(dist);
}

"""Follow-hops from ``src`` to ``dst``; -1 if unknown or unreachable."""
def separation(net: Roster, src: str, dst: str) -> int {
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
    frontier: list[Person] = [start];
    depth = 0;
    while len(frontier) > 0 {
        depth += 1;
        frontier = _expand(frontier, dist, depth);
        if dst in dist {
            return dist[dst];
        }
    }
    return -1;
}
