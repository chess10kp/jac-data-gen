"""TheLarkInn/aipm#1247 — Cargo build-unit dependency graph for timing reports."""

node BuildUnit {
    has name: str;
    has seconds: float = 0.0;
}

edge Depends {}

walker TransitiveWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with BuildUnit entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin {
            self.found.append(here.name);
        }
        visit [->:Depends:->][?:BuildUnit];
    }
}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with BuildUnit entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin {
            self.found.append(here.name);
        }
        visit [<-:Depends:<-][?:BuildUnit];
    }
}

walker DepPathWalk {
    has target: str = "";
    has max_depth: int = 12;
    has trail: list[str] = [];
    has paths: list[list[str]] = [];

    can step with BuildUnit entry {
        if here.name in self.trail { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.name);
        if here.name == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        if len(nt) >= self.max_depth { skip; }
        kids = [here ->:Depends:->][?:BuildUnit];
        nms: list[str] = [];
        for n in kids { nms.append(n.name); }
        for nm in sorted(nms) {
            for n in kids {
                if n.name == nm {
                    n spawn DepPathWalk(
                        target=self.target,
                        max_depth=self.max_depth,
                        trail=nt,
                        paths=self.paths,
                    );
                }
            }
        }
    }
}

obj BuildGraph {
    has times: dict[str, float] = {};
    has deps: dict[str, list[str]] = {};
    has units: dict[str, BuildUnit] = {};

    def add_unit(name: str, seconds: float = 0.0) -> None {
        self.times[name] = seconds;
        self.deps.setdefault(name, []);
        if name not in self.units {
            nd = BuildUnit(name=name, seconds=seconds);
            root ++> nd;
            self.units[name] = nd;
        } else {
            self.units[name].seconds = seconds;
        }
    }

    def add_edge(consumer: str, dep: str) -> None {
        if consumer in self.deps and dep in self.times {
            self.deps[consumer].append(dep);
            c = self.units.get(consumer, None);
            d = self.units.get(dep, None);
            if c is not None and d is not None { c +>:Depends:+> d; }
        }
    }
}

def load_build_graph(
    units: list[tuple[str, float]],
    edges: list[tuple[str, str]],
) -> BuildGraph {
    g = BuildGraph();
    for (name, secs) in units {
        g.add_unit(name, secs);
    }
    for (src, dst) in edges {
        g.add_edge(src, dst);
    }
    return g;
}

def _base_name(unit: str) -> str {
    if "@" in unit {
        return unit.split("@", 1)[0];
    }
    return unit;
}

def _slow_key(row: tuple[str, float]) -> tuple[float, str] {
    return (-row[1], row[0]);
}

def transitive_deps(g: BuildGraph, `root: str) -> list[str] {
    if `root not in g.times { return []; }
    nd = g.units.get(`root, None);
    if nd is None { return []; }
    w = nd spawn TransitiveWalk(claimed={}, found=[], origin=`root);
    return sorted(w.found);
}

def downstream_units(g: BuildGraph, `root: str) -> list[str] {
    if `root not in g.times { return []; }
    nd = g.units.get(`root, None);
    if nd is None { return []; }
    w = nd spawn DownstreamWalk(claimed={}, found=[], origin=`root);
    return sorted(w.found);
}

def duplicate_base_names(g: BuildGraph) -> list[str] {
    buckets: dict[str, dict[str, bool]] = {};
    for unit in g.times {
        base = _base_name(unit);
        if base not in buckets { buckets[base] = {}; }
        buckets[base][unit] = True;
    }
    out: list[str] = [];
    for (base, variants) in buckets.items() {
        cnt = 0;
        for _ in variants.keys() { cnt += 1; }
        if cnt > 1 { out.append(base); }
    }
    return sorted(out);
}

def dependency_paths(
    g: BuildGraph,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]] {
    if source not in g.times or target not in g.times { return []; }
    nd = g.units.get(source, None);
    if nd is None { return []; }
    w = nd spawn DepPathWalk(
        target=target,
        max_depth=max_depth,
        trail=[],
        paths=[],
    );
    out: list[list[str]] = [];
    for p in w.paths {
        row: list[str] = [];
        for x in p { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}

def slowest_units(g: BuildGraph, threshold: float) -> list[tuple[str, float]] {
    hot: list[tuple[str, float]] = [];
    for n in g.times {
        if g.times[n] >= threshold {
            hot.append((n, g.times[n]));
        }
    }
    return sorted(hot, key=_slow_key);
}
