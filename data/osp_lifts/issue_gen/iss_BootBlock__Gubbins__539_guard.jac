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

test "containment closure and kit count" {
    add_item("box", is_kit=True);
    add_item("pouch", is_kit=True);
    add_item("pallet", is_kit=True);
    add_item("screw");
    add_kit_component("box", "pouch");
    add_kit_component("pouch", "screw");
    add_kit_component("box", "pallet");
    assert direct_components("box") == ["pallet", "pouch"];
    assert all_components("box") == ["pallet", "pouch", "screw"];
    assert all_components("screw") == [];
    assert kit_count() == 3;
}

test "pre-write validation refuses loops and leaves table untouched" {
    add_item("kx", is_kit=True);
    add_item("ky", is_kit=True);
    add_kit_component("kx", "ky");
    try {
        add_kit_component("ky", "kx");
        assert False, "expected refusal";
    } except ValueError {
        assert True;
    }
    try {
        add_kit_component("ky", "ky");
        assert False, "expected self-containment refusal";
    } except ValueError {
        assert True;
    }
    assert len(direct_components("ky")) == 0;
}

test "diamond counted once" {
    add_item("da", is_kit=True);
    add_item("db1", is_kit=True);
    add_item("db2", is_kit=True);
    add_item("dsh");
    add_kit_component("da", "db1");
    add_kit_component("da", "db2");
    add_kit_component("db1", "dsh");
    add_kit_component("db2", "dsh");
    assert all_components("da") == ["db1", "db2", "dsh"];
}

test "persisted merged cycle stays finite and is detected" {
    add_item("mx", is_kit=True);
    add_item("my", is_kit=True);
    add_kit_component("mx", "my");
    # adversarial sync merge bypassing validation: inject the back edge
    items["my"] +>:Contains:+> items["mx"];
    items["mx"] +>:ContainedBy:+> items["my"];
    assert all_components("mx") == ["my"], all_components("mx");
    assert has_containment_cycle("mx");
    assert not has_containment_cycle("box");
}

test "errors preserved" {
    add_item("zz", is_kit=True);
    try {
        add_kit_component("ghost", "zz");
        assert False;
    } except KeyError {
        assert True;
    }
    try {
        add_kit_component("zz", "zz");  # zz IS a kit: self-containment
        assert False;
    } except ValueError {
        assert True;
    }
    try {
        add_item("zy");
        add_kit_component("zy", "zz");  # zy is not a kit
        assert False;
    } except ValueError {
        assert True;
    }
}
