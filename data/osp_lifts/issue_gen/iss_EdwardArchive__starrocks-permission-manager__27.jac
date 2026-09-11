"""Data lineage DAG for StarRocks VIEW/MV dependencies.

EdwardArchive/starrocks-permission-manager#27 lifted to OSP: catalog objects
become LineageObj nodes; (dependent, source) refs become DependsOn / Feeds
typed edges. Deque BFS upstream and downstream closures become budgeted
UpFlood / DownFlood walkers with claim-once maps; MV cycle detection is a
CycleProbe DFS that shares a gray/black color map across spawns.
"""
node LineageObj {
    has fqn: str;
    has kind: str;
}
edge DependsOn {}
edge Feeds {}

glob MAX_LINEAGE_DEPTH: int = 5;

obj LineageCatalog {
    has nodes: dict[str, LineageObj];
    has mv_fqns: list[str] = [];

    def resolve(fqn: str) -> LineageObj | None {
        return self.nodes.get(fqn);
    }
}

def build_catalog(objects: list[tuple[str, str]], refs: list[tuple[str, str]]) -> LineageCatalog {
    cat = LineageCatalog(nodes={}, mv_fqns=[]);
    for (fqn, kind) in objects {
        n = LineageObj(fqn=fqn, kind=kind);
        root ++> n;
        cat.nodes[fqn] = n;
        if kind == "MV" {
            cat.mv_fqns.append(fqn);
        }
    }
    for (dep, src) in refs {
        d = cat.resolve(dep);
        s = cat.resolve(src);
        if d is not None and s is not None {
            d +>:DependsOn:+> s;
            s +>:Feeds:+> d;
        }
    }
    return cat;
}

walker UpFlood {
    # Cycle policy: claim-once map; revisits skip (never disengage on revisit).
    has seen: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_fqn: str = "";
    has budget: int = 0;

    can step with LineageObj entry {
        if here.fqn in self.seen {
            skip;
        }
        self.seen[here.fqn] = True;
        if here.fqn != self.start_fqn {
            self.reached.append(str(here.fqn));
        }
        if self.budget <= 0 {
            disengage;
        }
        for up in [here ->:DependsOn:->] {
            up spawn UpFlood(seen=self.seen, reached=self.reached,
                             start_fqn=self.start_fqn, budget=self.budget - 1);
        }
    }
}

walker DownFlood {
    has seen: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_fqn: str = "";

    can step with LineageObj entry {
        if here.fqn in self.seen {
            skip;
        }
        self.seen[here.fqn] = True;
        if here.fqn != self.start_fqn {
            self.reached.append(str(here.fqn));
        }
        for dn in [here ->:Feeds:->] {
            dn spawn DownFlood(seen=self.seen, reached=self.reached, start_fqn=self.start_fqn);
        }
    }
}

walker CycleProbe {
    has color: dict[str, int] = {};
    has hit: dict[str, bool] = {};

    can step with LineageObj entry {
        if "found" in self.hit and self.hit["found"] {
            disengage;
        }
        c = 0;
        if here.fqn in self.color {
            c = self.color[here.fqn];
        }
        if c == 1 {
            self.hit["found"] = True;
            disengage;
        }
        if c == 2 {
            skip;
        }
        self.color[here.fqn] = 1;
        for up in [here ->:DependsOn:->] {
            up spawn CycleProbe(color=self.color, hit=self.hit);
        }
        self.color[here.fqn] = 2;
    }
}

def direct_sources(cat: LineageCatalog, fqn: str) -> list[str] {
    anchor = cat.resolve(fqn);
    if anchor is None {
        return [];
    }
    out: list[str] = [];
    for up in [anchor ->:DependsOn:->] {
        out.append(str(up.fqn));
    }
    return sorted(out);
}

def upstream_lineage(cat: LineageCatalog, fqn: str, max_depth: int = MAX_LINEAGE_DEPTH) -> list[str] {
    anchor = cat.resolve(fqn);
    if anchor is None {
        return [];
    }
    w = anchor spawn UpFlood(seen={}, reached=[], start_fqn=fqn, budget=max_depth);
    return sorted(w.reached);
}

def downstream_impact(cat: LineageCatalog, fqn: str) -> list[str] {
    anchor = cat.resolve(fqn);
    if anchor is None {
        return [];
    }
    w = anchor spawn DownFlood(seen={}, reached=[], start_fqn=fqn);
    return sorted(w.reached);
}

def has_circular_mv(cat: LineageCatalog) -> bool {
    for fqn in cat.mv_fqns {
        target = cat.resolve(fqn);
        if target is None {
            continue;
        }
        w = target spawn CycleProbe(color={}, hit={});
        if "found" in w.hit and w.hit["found"] {
            return True;
        }
    }
    return False;
}
