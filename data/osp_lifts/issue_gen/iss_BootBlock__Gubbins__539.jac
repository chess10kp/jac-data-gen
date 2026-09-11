"""Kit containment lifted to OSP (BootBlock/Gubbins#539).

"kit contains component" becomes a pair of typed edges -- ``Contains``
(kit --> component) and its inverse ``ContainedBy`` -- so the pre-write
validation walk and the transitive component expansion are plain forward
hops over typed edges instead of recursive table scans. The source's
policies survive verbatim: a link that would close a loop is refused
before write, an already-corrupt (merged-in) containment cycle raises
``ContainmentCycleError`` on read instead of overflowing the stack, and
the claim-map skip keeps every closure finite on diamonds.
"""

node Item {
    has iid: str;
    has is_kit: bool;
}

edge Contains: Item --> Item {}

edge ContainedBy: Item --> Item {}

glob items: dict[str, Item] = {};


def add_item(iid: str, is_kit: bool = False) -> None {
    root ++> (n := Item(iid=iid, is_kit=is_kit));
    items[iid] = n;
}


def direct_components(kit: str) -> list[str] {
    out: set[str] = set();
    for c in [items[kit] ->:Contains:->] {
        out.add(c.iid);
    }
    return sorted(out);
}


walker DescendsTo {
    """Claims the component closure below the entry node."""
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has hit_cycle: bool = False;

    can go with Item entry {
        if here.iid in self.claimed {
            self.hit_cycle = True;
            return;
        }
        self.claimed[here.iid] = True;
        self.found.append(here.iid);
        for c in [here ->:Contains:->] {
            sub = DescendsTo(claimed=self.claimed);
            c spawn sub;
            self.found.extend(sub.found);
        }
    }
}


def add_kit_component(kit: str, component: str) -> None {
    # pre-write validation: refuse any link that closes a containment loop
    if kit not in items or component not in items {
        raise KeyError(kit);
    }
    if not items[kit].is_kit {
        raise ValueError("not a kit");
    }
    if kit == component {
        raise ValueError("self-containment");
    }
    w = items[component] spawn DescendsTo(claimed={});
    if kit in w.found {
        raise ValueError("kit inside its own component");
    }
    items[kit] +>:Contains:+> items[component];
    items[component] +>:ContainedBy:+> items[kit];
}


def all_components(kit: str) -> list[str] {
    # transitive components; revisits skipped, always finite
    if kit not in items {
        raise KeyError(kit);
    }
    w = items[kit] spawn DescendsTo(claimed={});
    out: set[str] = set(w.found);
    out.discard(kit);
    return sorted(out);
}


walker CycleProbe {
    """Path-scoped DFS: flags only genuine ancestor-path repeats."""
    has path_seen: set[str] = set();
    has hit_cycle: bool = False;

    can go with Item entry {
        if here.iid in self.path_seen {
            self.hit_cycle = True;
            return;
        }
        for c in [here ->:Contains:->] {
            sub = CycleProbe(path_seen=self.path_seen | {here.iid});
            c spawn sub;
            if sub.hit_cycle {
                self.hit_cycle = True;
                return;
            }
        }
    }
}


def has_containment_cycle(kit: str) -> bool {
    # true when any root-to-node path from kit closes a loop
    if kit not in items {
        raise KeyError(kit);
    }
    w = items[kit] spawn CycleProbe();
    return w.hit_cycle;
}


def kit_count() -> int {
    n = 0;
    for iid in sorted(items.keys()) {
        if items[iid].is_kit {
            n += 1;
        }
    }
    return n;
}
