"""Ferry network planner lifted to OSP.

Islands become Island nodes; seasonal lines become undirected
FerryRoute edges. Cluster grouping spawns one claiming walker per
undiscovered island (shared claim map = explicit cycle policy for
ring-shaped ferry routes); point-to-point checks flood with early
disengage on arrival.
"""
node Island {
    has name: str;
}
edge FerryRoute {}

"""Loader handle: island names resolve through this lookup map."""
obj Archipelago {
    has isles: dict[str, Island];
    has order: list[str];

    def resolve(name: str) -> Island | None {
        return self.isles.get(name);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def build_ferryweb(islands: list[str], routes: list[tuple[str, str]]) -> Archipelago {
    web = Archipelago(isles={}, order=[]);
    for i in islands {
        n = Island(name=i);
        root ++> n;
        web.isles[i] = n;
        web.order.append(i);
    }
    for (a, b) in routes {
        ia = web.isles[a];
        ib = web.isles[b];
        ia +>:FerryRoute:+> ib;
        ib +>:FerryRoute:+> ia;
    }
    return web;
}

walker GroupFlood {
    has claimed: dict[str, bool] = {};
    has members: list[str] = [];

    can step with Island entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.members.append(here.name);
        visit [->:FerryRoute:->] else { disengage; }
    }
}

walker VoyageCheck {
    has target: str;
    has found: bool = False;
    has claimed: dict[str, bool] = {};
    has started: bool = False;

    can step with Island entry {
        if not self.started {
            self.started = True;
            self.claimed[here.name] = True;
            visit [->:FerryRoute:->] else { disengage; }
        } else {
            if here.name == self.target {
                self.found = True;
                disengage;
            }
            if here.name in self.claimed {
                skip;
            }
            self.claimed[here.name] = True;
            visit [->:FerryRoute:->] else { disengage; }
        }
    }
}

"""Connected clusters; each group sorted inside, groups ordered by the
fixture order of their first-discovered island."""
def island_groups(web: Archipelago) -> list[list[str]] {
    claimed: dict[str, bool] = {};
    groups: list[list[str]] = [];
    for name in web.order {
        if name in claimed {
            continue;
        }
        start = web.isles[name];
        w = start spawn GroupFlood(claimed=claimed);
        groups.append(sorted(w.members));
    }
    return groups;
}

"""True when a passenger can hop from ``src`` to ``dst``."""
def can_travel(web: Archipelago, src: str, dst: str) -> bool {
    start = web.resolve(src);
    if start is None {
        return False;
    }
    if web.resolve(dst) is None {
        return False;
    }
    if src == dst {
        return True;
    }
    w = start spawn VoyageCheck(target=dst);
    return w.found;
}
