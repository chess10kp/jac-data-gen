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
