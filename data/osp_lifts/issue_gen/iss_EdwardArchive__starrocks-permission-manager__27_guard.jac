"""Guard: candidate source + hidden tests (pinned semantics from Python)."""
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

def _fixture() -> LineageCatalog {
    return build_catalog(
        [
            ("analytics.customers", "TABLE"),
            ("analytics.orders", "TABLE"),
            ("analytics.products", "TABLE"),
            ("analytics.revenue_summary", "MV"),
            ("analytics.quarterly_report", "VIEW"),
        ],
        [
            ("analytics.revenue_summary", "analytics.customers"),
            ("analytics.revenue_summary", "analytics.orders"),
            ("analytics.revenue_summary", "analytics.products"),
            ("analytics.quarterly_report", "analytics.revenue_summary"),
        ],
    );
}

test "phase1 direct sources and phase2 closures" {
    cat = _fixture();
    assert direct_sources(cat, "analytics.quarterly_report") == ["analytics.revenue_summary"];
    assert direct_sources(cat, "analytics.revenue_summary") == [
        "analytics.customers", "analytics.orders", "analytics.products",
    ];
    assert upstream_lineage(cat, "analytics.quarterly_report", max_depth=1) == ["analytics.revenue_summary"];
    assert upstream_lineage(cat, "analytics.quarterly_report", max_depth=2) == [
        "analytics.customers", "analytics.orders", "analytics.products", "analytics.revenue_summary",
    ];
    assert downstream_impact(cat, "analytics.customers") == [
        "analytics.quarterly_report", "analytics.revenue_summary",
    ];
    assert downstream_impact(cat, "analytics.quarterly_report") == [];
}

test "unknown fqn tolerates empty results" {
    cat = _fixture();
    assert direct_sources(cat, "ghost.table") == [];
    assert upstream_lineage(cat, "ghost.table") == [];
    assert downstream_impact(cat, "ghost.table") == [];
}

test "adversarial-order diamond upstream closure" {
    # Edge insertion order forces revisit before deeper first-visits on shared mid.
    cat = build_catalog(
        [
            ("db.t1", "TABLE"), ("db.t2", "TABLE"), ("db.mid", "VIEW"), ("db.top", "VIEW"),
        ],
        [
            ("db.top", "db.mid"),
            ("db.mid", "db.t1"),
            ("db.mid", "db.t2"),
        ],
    );
    assert upstream_lineage(cat, "db.top", max_depth=1) == ["db.mid"];
    assert upstream_lineage(cat, "db.top", max_depth=2) == ["db.mid", "db.t1", "db.t2"];
}

test "adversarial-order diamond downstream impact" {
    cat = build_catalog(
        [
            ("db.t1", "TABLE"), ("db.t2", "TABLE"), ("db.mid", "VIEW"),
            ("db.top", "VIEW"), ("db.d1", "VIEW"), ("db.d2", "VIEW"),
        ],
        [
            ("db.d2", "db.top"),
            ("db.top", "db.mid"),
            ("db.d1", "db.top"),
            ("db.mid", "db.t2"),
            ("db.mid", "db.t1"),
        ],
    );
    assert downstream_impact(cat, "db.t1") == ["db.d1", "db.d2", "db.mid", "db.top"];
}

test "mv cycles detected; pure view cycles ignored" {
    acyclic = _fixture();
    assert has_circular_mv(acyclic) is False;
    cyclic = build_catalog(
        [("db.mv_a", "MV"), ("db.mv_b", "MV"), ("db.base", "TABLE")],
        [("db.mv_a", "db.mv_b"), ("db.mv_b", "db.mv_a"), ("db.mv_b", "db.base")],
    );
    assert has_circular_mv(cyclic) is True;
    view_only = build_catalog(
        [("db.v_a", "VIEW"), ("db.v_b", "VIEW")],
        [("db.v_a", "db.v_b"), ("db.v_b", "db.v_a")],
    );
    assert has_circular_mv(view_only) is False;
}

test "cyclic upstream walk terminates" {
    cat = build_catalog(
        [("db.mv_a", "MV"), ("db.mv_b", "MV")],
        [("db.mv_a", "db.mv_b"), ("db.mv_b", "db.mv_a")],
    );
    assert upstream_lineage(cat, "db.mv_a", max_depth=10) == ["db.mv_b"];
    assert downstream_impact(cat, "db.mv_a") == ["db.mv_b"];
}
