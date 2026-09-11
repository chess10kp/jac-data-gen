"""Neighborhood portal friend circles, lifted to OSP.

The adjacency dict becomes Person nodes joined by undirected FriendWith
edges; the deque BFS becomes a flooding walker. The claim map is the
explicit cycle policy: jac 0.36.1 walkers do not dedupe on cyclic graphs,
so every entry is guarded once.
"""
node Person {
    has name: str;
}
edge FriendWith {}

"""Loader handle: id-string parameters resolve through this lookup map."""
obj Portal {
    has people: dict[str, Person];
    has roster: list[str];

    def resolve(name: str) -> Person | None {
        return self.people.get(name);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def build_network(members: list[str], friendships: list[tuple[str, str]]) -> Portal {
    net = Portal(people={}, roster=[]);
    for m in members {
        p = Person(name=m);
        root ++> p;
        net.people[m] = p;
        net.roster.append(m);
    }
    for (a, b) in friendships {
        pa = net.people[a];
        pb = net.people[b];
        pa +>:FriendWith:+> pb;
        pb +>:FriendWith:+> pa;
    }
    return net;
}

walker CircleFlood {
    has claimed: dict[str, bool] = {};
    has members: list[str] = [];

    can step with Person entry {
        # Cycle policy: claim-once; skip (not disengage) keeps sibling
        # visits alive while refusing revisits.
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.members.append(here.name);
        visit [->:FriendWith:->] else { disengage; }
    }
}

"""All ids in the friend circle containing ``member`` (sorted)."""
def circle_of(graph: Portal, member: str) -> list[str] {
    start = graph.resolve(member);
    if start is None {
        return [];
    }
    w = start spawn CircleFlood(claimed={});
    return sorted(w.members);
}

"""Number of disjoint friend circles in the network."""
def circle_count(graph: Portal) -> int {
    claimed: dict[str, bool] = {};
    count = 0;
    for m in graph.roster {
        if m in claimed {
            continue;
        }
        start = graph.people[m];
        _ = start spawn CircleFlood(claimed=claimed);
        count += 1;
    }
    return count;
}
