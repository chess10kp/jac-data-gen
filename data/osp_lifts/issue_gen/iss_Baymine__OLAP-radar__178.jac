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
    # Cycle policy: claim-once map; revisits skip (never disengage on revisit).
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
