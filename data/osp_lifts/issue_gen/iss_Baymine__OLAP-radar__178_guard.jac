"""OSP lift: OLAP ecosystem upstream lineage digest. Baymine/OLAP-radar#178."""

node EcosystemPart {
    has name: str;
}

edge DependsOn {}

glob MAX_LINEAGE_DEPTH: int = 5;

obj DigestCatalog {
    has nodes: dict[str, EcosystemPart];

    def resolve(name: str) -> EcosystemPart | None {
        return self.nodes.get(name);
    }
}

walker UpstreamWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_name: str = "";
    has budget: int = 0;

    can step with EcosystemPart entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if here.name != self.start_name {
            self.reached.append(str(here.name));
        }
        if self.budget <= 0 {
            disengage;
        }
        for up in [here ->:DependsOn:->] {
            up spawn UpstreamWalk(
                claimed=self.claimed,
                reached=self.reached,
                start_name=self.start_name,
                budget=self.budget - 1,
            );
        }
    }
}

def build_catalog(components: list[str], refs: list[tuple[str, str]]) -> DigestCatalog {
    cat = DigestCatalog(nodes={});
    for c in components {
        n = EcosystemPart(name=c);
        root ++> n;
        cat.nodes[c] = n;
    }
    for (dep, src) in refs {
        d = cat.resolve(dep);
        s = cat.resolve(src);
        if d is not None and s is not None {
            d +>:DependsOn:+> s;
        }
    }
    return cat;
}

def direct_upstream(cat: DigestCatalog, name: str) -> list[str] {
    anchor = cat.resolve(name);
    if anchor is None {
        return [];
    }
    out: list[str] = [];
    for up in [anchor ->:DependsOn:->] {
        out.append(str(up.name));
    }
    return sorted(out);
}

def upstream_closure(
    cat: DigestCatalog,
    name: str,
    max_depth: int = MAX_LINEAGE_DEPTH,
) -> list[str] {
    anchor = cat.resolve(name);
    if anchor is None {
        return [];
    }
    w = anchor spawn UpstreamWalk(claimed={}, reached=[], start_name=name, budget=max_depth);
    return sorted(w.reached);
}

def lineage_digest(
    cat: DigestCatalog,
    name: str,
    max_depth: int = MAX_LINEAGE_DEPTH,
) -> list[str] {
    if cat.resolve(name) is None {
        return [];
    }
    direct = direct_upstream(cat, name);
    trans = upstream_closure(cat, name, max_depth);
    merged: list[str] = [name];
    for x in direct {
        merged.append(x);
    }
    for x in trans {
        merged.append(x);
    }
    return sorted(set(merged));
}

def _fixture() -> DigestCatalog {
    return build_catalog(
        ["doris", "gluten", "velox", "arrow", "iceberg"],
        [
            ("doris", "gluten"),
            ("doris", "iceberg"),
            ("gluten", "velox"),
            ("velox", "arrow"),
        ],
    );
}

test "doris ecosystem upstream and digest" {
    cat = _fixture();
    assert direct_upstream(cat, "doris") == ["gluten", "iceberg"];
    assert upstream_closure(cat, "doris", max_depth=1) == ["gluten", "iceberg"];
    assert upstream_closure(cat, "doris", max_depth=2) == ["gluten", "iceberg", "velox"];
    assert lineage_digest(cat, "doris") == [
        "arrow", "doris", "gluten", "iceberg", "velox",
    ];
}

test "unknown component tolerates empty results" {
    cat = _fixture();
    assert direct_upstream(cat, "ghost") == [];
    assert upstream_closure(cat, "ghost") == [];
    assert lineage_digest(cat, "ghost") == [];
}

test "adversarial-order diamond upstream closure" {
    # Edge insertion forces revisit on shared mid before deeper first-visits.
    cat = build_catalog(
        ["top", "a", "b", "mid", "leaf"],
        [
            ("top", "mid"),
            ("b", "mid"),
            ("mid", "leaf"),
            ("a", "mid"),
        ],
    );
    assert upstream_closure(cat, "top", max_depth=2) == ["a", "b", "leaf", "mid"];
    assert lineage_digest(cat, "top", max_depth=2) == ["a", "b", "leaf", "mid", "top"];
}

test "cyclic upstream walk terminates" {
    cat = build_catalog(
        ["x", "y", "z"],
        [("x", "y"), ("y", "z"), ("z", "x")],
    );
    got = upstream_closure(cat, "x", max_depth=10);
    assert got == ["y", "z"];
    assert len(got) == 2;
}
