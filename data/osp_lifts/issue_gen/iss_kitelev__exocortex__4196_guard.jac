"""kitelev/exocortex#4196 lifted to OSP: zone hierarchy as Contains edges."""
node ZoneNode {
    has name: str;
    has loads: int = 0;
}

edge Contains {}

obj ZoneIndex {
    has zones: dict[str, ZoneNode];

    def resolve(name: str) -> ZoneNode | None {
        return self.zones.get(name);
    }
}

def build_zone_tree() -> ZoneIndex {
    return ZoneIndex(zones={});
}

def add_zone(ix: ZoneIndex, name: str, parent: str | None = None) {
    p = None;
    if parent is not None {
        p = ix.resolve(parent);
        if p is None {
            raise KeyError("unknown parent zone");
        }
    }
    z = ZoneNode(name=name);
    root ++> z;
    ix.zones[name] = z;
    if p is not None {
        p +>:Contains:+> z;
    }
}

def assign(ix: ZoneIndex, zone: str, n: int = 1) {
    z = ix.resolve(zone);
    if z is None {
        raise KeyError("unknown zone");
    }
    z.loads += n;
}

def direct_capacity(ix: ZoneIndex, zone: str) -> int {
    z = ix.resolve(zone);
    if z is None {
        raise KeyError("unknown zone");
    }
    return z.loads;
}

"""Subtree sum; claim map tolerates forged cycles without double counting."""
walker SubtreeLoad {
    has claimed: dict[str, bool];
    has total: int = 0;

    can step with ZoneNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.total += here.loads;
        visit [->:Contains:->];
    }
}

def aggregate(ix: ZoneIndex, zone: str) -> int {
    z = ix.resolve(zone);
    if z is None {
        raise KeyError("unknown zone");
    }
    w = z spawn SubtreeLoad(claimed={});
    return w.total;
}

"""Nearest-first parent chain; claim map breaks corrupt cycles."""
walker ParentChain {
    has claimed: dict[str, bool];
    has chain: list[str] = [];

    can step with ZoneNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.chain.append(here.name);
        parents: list[ZoneNode] = [here <-:Contains:<-];
        if len(parents) == 0 {
            disengage;
        }
        visit [parents[0]];
    }
}

def ancestors(ix: ZoneIndex, zone: str) -> list[str] {
    z = ix.resolve(zone);
    if z is None {
        raise KeyError("unknown zone");
    }
    w = z spawn ParentChain(claimed={});
    out: list[str] = [];
    for n in w.chain[1:] {
        out.append(n);
    }
    return out;
}

"""Flood beneath a zone, recording first-arrival depth per zone."""
walker DepthFlood {
    has claimed: dict[str, bool];
    has depths: dict[str, int];
    has found: list[str] = [];

    can step with ZoneNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        d = self.depths.get(here.name);
        if d is None {
            d = 0;
        }
        self.found.append(here.name);
        kids: list[ZoneNode] = [here ->:Contains:->];
        for k in kids {
            kd = self.depths.get(k.name);
            if kd is None {
                self.depths[k.name] = d + 1;
            }
        }
        visit [->:Contains:->];
    }
}

def descendants(ix: ZoneIndex, zone: str, depth: int | None = None) -> list[str] {
    z = ix.resolve(zone);
    if z is None {
        raise KeyError("unknown zone");
    }
    w = z spawn DepthFlood(claimed={}, depths={});
    out: list[str] = [];
    for n in w.found {
        if n != zone {
            if depth is None {
                out.append(n);
            } else {
                d = w.depths.get(n);
                if d is not None {
                    if d == depth {
                        out.append(n);
                    }
                }
            }
        }
    }
    return sorted(out);
}

test "capacity rollup over the containment tree" {
    ix = build_zone_tree();
    add_zone(ix, "TBank");
    add_zone(ix, "Sales Offering", "TBank");
    add_zone(ix, "Operations", "TBank");
    add_zone(ix, "TOOS Group", "Sales Offering");
    add_zone(ix, "People Management", "TOOS Group");
    add_zone(ix, "Value Delivery", "TOOS Group");
    assign(ix, "People Management", 17);
    assign(ix, "Value Delivery", 5);
    assign(ix, "Operations", 11);
    assign(ix, "TBank", 3);
    assert aggregate(ix, "TOOS Group") == 22;
    assert aggregate(ix, "Sales Offering") == 22;
    assert aggregate(ix, "TBank") == 36;
    assert aggregate(ix, "Operations") == 11;
    assert direct_capacity(ix, "TBank") == 3;
    assert direct_capacity(ix, "TOOS Group") == 0;
}

test "ancestor chain and depth-filtered descendants" {
    ix = build_zone_tree();
    add_zone(ix, "TBank");
    add_zone(ix, "Sales Offering", "TBank");
    add_zone(ix, "Operations", "TBank");
    add_zone(ix, "TOOS Group", "Sales Offering");
    add_zone(ix, "People Management", "TOOS Group");
    assert ancestors(ix, "People Management") == ["TOOS Group", "Sales Offering", "TBank"];
    assert ancestors(ix, "TBank") == [];
    assert descendants(ix, "TBank") == ["Operations", "People Management", "Sales Offering", "TOOS Group"];
    assert descendants(ix, "TBank", depth=1) == ["Operations", "Sales Offering"];
    assert descendants(ix, "TBank", depth=2) == ["TOOS Group"];
    assert descendants(ix, "People Management") == [];
}

test "unknown ids raise KeyError" {
    ix = build_zone_tree();
    add_zone(ix, "TBank");
    try { aggregate(ix, "ghost"); assert False, "expected KeyError"; }
    except KeyError { assert True; }
    try { ancestors(ix, "ghost"); assert False, "expected KeyError"; }
    except KeyError { assert True; }
    try { assign(ix, "ghost"); assert False, "expected KeyError"; }
    except KeyError { assert True; }
    try { add_zone(ix, "x", "ghost"); assert False, "expected KeyError"; }
    except KeyError { assert True; }
}

test "forged two-cycle terminates without double counting" {
    ix = build_zone_tree();
    add_zone(ix, "A");
    add_zone(ix, "B", "A");
    assign(ix, "A", 4);
    assign(ix, "B", 6);
    a = ix.resolve("A");
    b = ix.resolve("B");
    b +>:Contains:+> a;    # forge A <-> B, bypassing the facade
    assert aggregate(ix, "A") == 10;
    assert ancestors(ix, "A") == ["B"];
    assert descendants(ix, "A") == ["B"];
}

test "diamond counts the shared leaf exactly once" {
    ix = build_zone_tree();
    add_zone(ix, "top");
    add_zone(ix, "l", "top");
    add_zone(ix, "r", "top");
    add_zone(ix, "bot", "l");
    r = ix.resolve("r");
    bot = ix.resolve("bot");
    r +>:Contains:+> bot;    # second path to bot
    assign(ix, "bot", 7);
    assign(ix, "top", 1);
    assert aggregate(ix, "top") == 8;
    assert descendants(ix, "top") == ["bot", "l", "r"];
}
