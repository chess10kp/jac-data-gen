"""Location-hierarchy encounter queries, lifted to OSP.

Locations and encounters become node archetypes; the parent_id chain
becomes a typed ChildOf edge (child to parent) and the encounter
attachment becomes a typed At edge. The while-loop parent ascent becomes
a walker over outbound ChildOf edges, the recursive children-index
descent becomes a walker over inbound ChildOf edges, and proximity
aggregation reads encounters off the near locations through their
inbound At edges. Claim maps keep the walks terminating (cycle policy
for malformed hierarchies); results are sorted, matching the source.
Ref: beyond-immersion/bannou-service#313
"""
node Location {
    has loc_id: str;
}
node Encounter {
    has enc_id: str;
}
edge ChildOf {}
edge At {}

"""Loader handle: location ids resolve through this lookup map."""
obj World {
    has locs: dict[str, Location];

    def resolve(lid: str) -> Location | None {
        return self.locs.get(lid);
    }
}

"""Deterministic fresh-graph builder from location and encounter rows."""
def load_world(locations: list[dict], encounters: list[dict]) -> World {
    w = World(locs={});
    # Every referenced location id gets a node, so ChildOf and At edges
    # always have definite endpoints regardless of row order.
    ids: set[str] = set();
    for row in locations {
        ids.add(row["id"]);
        pid = row.get("parent_id");
        if pid is not None {
            ids.add(pid);
        }
    }
    for e in encounters {
        ids.add(e["location_id"]);
    }
    for lid in ids {
        l = Location(loc_id=lid);
        root ++> l;
        w.locs[lid] = l;
    }
    # Hierarchy edges: pass two, after all nodes exist.
    for row in locations {
        pid = row.get("parent_id");
        if pid is not None {
            child = w.locs.get(row["id"]);
            parent = w.locs.get(pid);
            if child is None {
                continue;
            }
            if parent is None {
                continue;
            }
            child +>:ChildOf:+> parent;
        }
    }
    # Encounter attachments.
    for e in encounters {
        en = Encounter(enc_id=e["id"]);
        root ++> en;
        loc = w.locs.get(e["location_id"]);
        if loc is None {
            continue;
        }
        en +>:At:+> loc;
    }
    return w;
}

walker AncestorsWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[Location] = [];

    can step with Location entry {
        # Cycle policy: one visit per location (malformed-parent guard).
        if here.loc_id in self.claimed {
            skip;
        }
        self.claimed[here.loc_id] = True;
        self.hits.append(here);
        visit [->:ChildOf:->];
    }
}

walker DescendantsWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[Location] = [];

    can step with Location entry {
        # Cycle policy: one visit per location (malformed-parent guard).
        if here.loc_id in self.claimed {
            skip;
        }
        self.claimed[here.loc_id] = True;
        self.hits.append(here);
        visit [<-:ChildOf:<-];
    }
}

"""Sorted ids of every ancestor of ``loc_id`` (parents upward)."""
def ancestors_of(locations: list[dict], loc_id: str) -> list {
    w = load_world(locations, []);
    start = w.resolve(loc_id);
    if start is None {
        return [];
    }
    wk = start spawn AncestorsWalk(claimed={}, hits=[]);
    return sorted([l.loc_id for l in wk.hits if l.loc_id != loc_id]);
}

"""Sorted ids of every descendant of ``loc_id`` (children downward)."""
def descendants_of(locations: list[dict], loc_id: str) -> list {
    w = load_world(locations, []);
    start = w.resolve(loc_id);
    if start is None {
        return [];
    }
    wk = start spawn DescendantsWalk(claimed={}, hits=[]);
    return sorted([l.loc_id for l in wk.hits if l.loc_id != loc_id]);
}

"""Sorted ids of encounters "near" ``loc_id``: exact, ancestors, descendants."""
def find_encounters(locations: list[dict], encounters: list[dict], loc_id: str) -> list {
    w = load_world(locations, encounters);
    start = w.resolve(loc_id);
    if start is None {
        return [];
    }
    up = start spawn AncestorsWalk(claimed={}, hits=[]);
    down = start spawn DescendantsWalk(claimed={}, hits=[]);
    seen_locs: dict[str, bool] = {};
    out: list[str] = [];
    for loc in up.hits {
        if loc.loc_id in seen_locs {
            continue;
        }
        seen_locs[loc.loc_id] = True;
        encs: list[Encounter] = [loc <-:At:<-];
        for enc in encs {
            out.append(enc.enc_id);
        }
    }
    for loc in down.hits {
        if loc.loc_id in seen_locs {
            continue;
        }
        seen_locs[loc.loc_id] = True;
        encs2: list[Encounter] = [loc <-:At:<-];
        for enc in encs2 {
            out.append(enc.enc_id);
        }
    }
    return sorted(out);
}
