"""Office buddy matcher lifted to OSP.

Coworkers become Person nodes joined by undirected WorksWith edges.
One-hop grabs and two-hop suggestion sweeps are walkers over typed edges;
the claim maps are the explicit cycle policy for desk-tie loops.
"""
node Person {
    has nick: str;
}
edge WorksWith {}

"""Loader handle: nicknames resolve through this lookup map."""
obj Office {
    has staff: dict[str, Person];

    def resolve(nick: str) -> Person | None {
        return self.staff.get(nick);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def build_office(nicknames: list[str], desk_ties: list[tuple[str, str]]) -> Office {
    office = Office(staff={});
    for n in nicknames {
        p = Person(nick=n);
        root ++> p;
        office.staff[n] = p;
    }
    for (a, b) in desk_ties {
        pa = office.staff[a];
        pb = office.staff[b];
        pa +>:WorksWith:+> pb;
        pb +>:WorksWith:+> pa;
    }
    return office;
}

walker NeighborGrab {
    has base: str;
    has names: list[str] = [];
    has claimed: dict[str, bool] = {};
    has seeding: bool = True;

    can step with Person entry {
        if self.seeding {
            self.seeding = False;
            self.claimed[here.nick] = True;
            visit [->:WorksWith:->] else { disengage; }
        } else {
            if here.nick in self.claimed {
                skip;
            }
            self.claimed[here.nick] = True;
            self.names.append(here.nick);
        }
    }
}

walker HopSweep {
    has dist: dict[str, int] = {};
    has depth: int = 0;
    has fresh: list[Person] = [];
    has seeding: bool = True;

    can step with Person entry {
        # Only the round's seed expands; freshly claimed nicknames wait
        # for the next round so hop counts stay exact.
        if self.seeding {
            self.seeding = False;
            visit [->:WorksWith:->] else { disengage; }
        } else {
            if here.nick in self.dist {
                skip;
            }
            self.dist[here.nick] = self.depth;
            self.fresh.append(here);
        }
    }
}

"""Claim one BFS round around ``seed`` at ``depth`` into ``dist``."""
def _sweep_round(seed: Person, dist: dict[str, int], depth: int) -> list[Person] {
    fresh: list[Person] = [];
    _ = seed spawn HopSweep(dist=dist, depth=depth, fresh=fresh);
    return fresh;
}

"""Shared direct desk neighbors of ``a`` and ``b`` (sorted)."""
def mutual_buddies(office: Office, a: str, b: str) -> list[str] {
    pa = office.resolve(a);
    if pa is None {
        return [];
    }
    pb = office.resolve(b);
    if pb is None {
        return [];
    }
    wa = pa spawn NeighborGrab(base=a);
    wb = pb spawn NeighborGrab(base=b);
    common: dict[str, bool] = {};
    for n in wa.names {
        common[n] = True;
    }
    out: list[str] = [];
    for n in wb.names {
        if n in common {
            out.append(n);
        }
    }
    return sorted(out);
}

"""Second-degree neighbors minus self and direct ties (sorted)."""
def suggestions(office: Office, who: str) -> list[str] {
    start = office.resolve(who);
    if start is None {
        return [];
    }
    dist: dict[str, int] = {};
    dist[who] = 0;
    frontier: list[Person] = [start];
    depth = 0;
    while len(frontier) > 0 and depth < 2 {
        depth += 1;
        nxt: list[Person] = [];
        for seed in frontier {
            nxt = nxt + _sweep_round(seed, dist, depth);
        }
        frontier = nxt;
    }
    out: list[str] = [];
    for (nick, d) in dist.items() {
        if d == 2 {
            out.append(nick);
        }
    }
    return sorted(out);
}

test "mutual buddies multiset" {
    office = build_office(["avi", "bree", "cal", "dee", "eli"], [("avi", "bree"), ("avi", "cal"), ("bree", "cal"), ("cal", "dee"), ("dee", "eli")]);
    assert mutual_buddies(office, "avi", "bree") == ["cal"];
    assert mutual_buddies(office, "avi", "dee") == ["cal"];
    assert mutual_buddies(office, "dee", "eli") == [];
}

test "suggestions exclude direct ties exactly once" {
    office = build_office(["avi", "bree", "cal", "dee", "eli"], [("avi", "bree"), ("avi", "cal"), ("bree", "cal"), ("cal", "dee"), ("dee", "eli")]);
    assert suggestions(office, "avi") == ["dee"];
    assert suggestions(office, "eli") == ["cal"];
    assert suggestions(office, "cal") == ["eli"];
}

test "diamond candidate appears once" {
    office = build_office(["a", "b", "c", "d"], [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")]);
    assert suggestions(office, "a") == ["d"];
    assert mutual_buddies(office, "b", "c") == ["a", "d"];
}

test "unknown nicknames" {
    office = build_office(["avi"], []);
    assert mutual_buddies(office, "zzz", "avi") == [];
    assert mutual_buddies(office, "avi", "zzz") == [];
    assert suggestions(office, "zzz") == [];
}
