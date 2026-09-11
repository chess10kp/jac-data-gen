"""TheLarkInn/aipm#1313 — transitive build lineage with forked feature-set paths."""

glob ROOT = "aipm";

node LineageRoot {}

node LineageUnit {
    has uid: str;
    has weight: float = 0.0;
}

edge UnitDep: LineageUnit --> LineageUnit {}

obj LineageHandle {
    has root_nd: LineageRoot;
    has features: dict[str, list[str]] = {};

    def init {
        self.features = {};
        self.root_nd = LineageRoot();
        root ++> self.root_nd;
        self._wire();
    }

    def _unit(uid: str, weight: float = 0.0) -> LineageUnit {
        nd = LineageUnit(uid=uid, weight=weight);
        self.root_nd ++> nd;
        return nd;
    }

    def _link(src: LineageUnit, dst: LineageUnit) {
        src +>:UnitDep():+> dst;
    }

    def _wire {
        aipm = self._unit("aipm", 1.0);
        jsonschema = self._unit("jsonschema", 22.6);
        reqwest = self._unit("reqwest", 5.0);
        rustls_ring = self._unit("rustls-ring", 22.7);
        rustls_aws = self._unit("rustls-aws", 22.1);
        aws = self._unit("aws-lc-sys", 83.9);
        libgit2 = self._unit("libgit2-sys", 70.0);
        syn = self._unit("syn", 27.4);
        self._link(aipm, jsonschema);
        self._link(aipm, libgit2);
        self._link(aipm, syn);
        self._link(jsonschema, reqwest);
        self._link(reqwest, rustls_ring);
        self._link(reqwest, rustls_aws);
        self._link(rustls_aws, aws);
        self.features = {
            "rustls-ring": ["ring", "tls12"],
            "rustls-aws": ["aws-lc-rs", "tls12"],
            "jsonschema": ["reqwest", "resolve-http", "tls-aws-lc-rs"],
        };
    }

    def find_unit(uid: str) -> LineageUnit | None {
        for nd in [self.root_nd -->][?:LineageUnit] {
            if nd.uid == uid { return nd; }
        }
        return None;
    }
}

def sort_units(items: list[LineageUnit]) -> list[LineageUnit] {
    names: list[str] = [];
    for it in items { names.append(it.uid); }
    names = sorted(names);
    out: list[LineageUnit] = [];
    for nm in names {
        for it in items {
            if it.uid == nm { out.append(it); }
        }
    }
    return out;
}

def _fresh_lineage() -> LineageHandle { return LineageHandle(); }

walker LineageReach {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can go with LineageUnit entry {
        if here.uid in self.claimed { skip; }
        self.claimed[here.uid] = True;
        self.names.append(here.uid);
        visit [->:UnitDep:->];
    }
}

walker ForkWalk {
    has trail: list[str] = [];
    has paths: list[list[str]] = [];
    has scope: dict[str, bool] = {};

    can go with LineageUnit entry {
        if here.uid not in self.scope { skip; }
        new_trail = self.trail + [here.uid];
        outs = sort_units([here ->:UnitDep:->][?:LineageUnit]);
        scoped: list[LineageUnit] = [];
        for nxt in outs {
            if nxt.uid in self.scope { scoped.append(nxt); }
        }
        if len(scoped) == 0 {
            self.paths.append(new_trail);
            skip;
        }
        for nxt in scoped {
            child = nxt spawn ForkWalk(trail=new_trail, paths=[], scope=self.scope);
            for p in child.paths {
                self.paths.append(p);
            }
        }
    }
}

walker FeatureReach {
    has claimed: dict[str, bool] = {};
    has feats: dict[str, list[str]] = {};
    has seeds: list[str] = [];
    has names: list[str] = [];
    has pending: list[str] = [];

    can run with LineageRoot entry {
        self.pending = sorted(self.seeds);
        while len(self.pending) > 0 {
            item = self.pending[0];
            self.pending = self.pending[1:];
            if item in self.claimed { continue; }
            self.claimed[item] = True;
            self.names.append(item);
            for nx in sorted(self.feats.get(item, [])) {
                self.pending.append(nx);
            }
        }
    }
}

def lineage_nodes(root_id: str, graph: LineageHandle | None = None) -> list[str] {
    g = graph;
    if g is None { g = _fresh_lineage(); }
    rt = g.find_unit(root_id);
    if rt is None { raise KeyError(root_id); }
    w = rt spawn LineageReach(claimed={}, names=[]);
    return sorted(w.names);
}

def fork_paths(root_id: str, graph: LineageHandle | None = None) -> list[list[str]] {
    g = graph;
    if g is None { g = _fresh_lineage(); }
    rt = g.find_unit(root_id);
    if rt is None { raise KeyError(root_id); }
    scope: dict[str, bool] = {};
    for nm in lineage_nodes(root_id, g) { scope[nm] = True; }
    w = rt spawn ForkWalk(trail=[], paths=[], scope=scope);
    return sorted(w.paths);
}

def feature_lineage(unit: str, graph: LineageHandle | None = None) -> list[str] {
    g = graph;
    if g is None { g = _fresh_lineage(); }
    if g.find_unit(unit) is None { raise KeyError(unit); }
    seeds = g.features.get(unit, []);
    w = g.root_nd spawn FeatureReach(
        claimed={}, feats=g.features, seeds=seeds, names=[], pending=[]
    );
    return sorted(w.names);
}

def heaviest_fork(root_id: str, graph: LineageHandle | None = None) -> list[str] {
    g = graph;
    if g is None { g = _fresh_lineage(); }
    best: list[str] = [];
    best_w = -1.0;
    for path in fork_paths(root_id, g) {
        w = 0.0;
        for uid in path {
            nd = g.find_unit(uid);
            if nd is not None { w += nd.weight; }
        }
        if w > best_w or (w == best_w and path < best) {
            best = path;
            best_w = w;
        }
    }
    return best;
}

def duplicate_lineage_crates(records: list[tuple[str, str]]) -> dict[str, list[str]] {
    acc: dict[str, list[str]] = {};
    for rec in records {
        crate = rec[0];
        version = rec[1];
        if crate not in acc { acc[crate] = []; }
        if version not in acc[crate] { acc[crate].append(version); }
    }
    out: dict[str, list[str]] = {};
    keys = sorted(acc.keys());
    for k in keys {
        if len(acc[k]) > 1 { out[k] = sorted(acc[k]); }
    }
    return out;
}
