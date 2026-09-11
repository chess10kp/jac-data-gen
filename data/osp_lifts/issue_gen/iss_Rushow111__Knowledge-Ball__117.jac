"""Rushow111/Knowledge-Ball#117 — KVOP acceptance audit (OSP lift)."""

obj KVOPGraph {
    has versions: dict[str, Version] = {};
}

node Version { has vid: str; has label: str = ""; }
edge Depends {}
edge Lineage {}

def _resolve(g: KVOPGraph, vid: str) -> Version | None {
    return g.versions.get(vid, None);
}

def load_kvop(
    versions: list[tuple[str, str]],
    depends: list[tuple[str, str]],
    lineage: list[tuple[str, str]],
) -> KVOPGraph {
    g = KVOPGraph(versions={});
    for (vid, label) in versions {
        nd = Version(vid=vid, label=label);
        root ++> nd;
        g.versions[vid] = nd;
    }
    for (child, parent) in lineage {
        c = g.versions.get(child, None);
        p = g.versions.get(parent, None);
        if c is not None and p is not None { c +>:Lineage:+> p; }
    }
    for (src, dst) in depends {
        a = g.versions.get(src, None);
        b = g.versions.get(dst, None);
        if a is not None and b is not None { a +>:Depends:+> b; }
    }
    return g;
}

walker LineageWalk {
    has claimed: dict[str, bool] = {};
    has ancestors: list[str] = [];
    can step with Version entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        self.ancestors.append(here.vid);
        visit [->:Lineage:->] else { disengage; };
    }
}

walker DepWalk {
    has origin: str = "";
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    can step with Version entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        if here.vid != self.origin { self.reached.append(here.vid); }
        visit [->:Depends:->] else { disengage; };
    }
}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has stack: list[str] = [];
    has found: bool = False;
    can step with Version entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        self.stack.append(here.vid);
        for nxt in [here ->:Depends:->][?:Version] {
            if nxt.vid in self.stack { self.found = True; }
        }
        visit [->:Depends:->] else { disengage; };
    }
}

def lineage_ancestors(g: KVOPGraph, vid: str) -> list[str] {
    anchor = _resolve(g, vid);
    if anchor is None { return []; }
    w = anchor spawn LineageWalk(claimed={}, ancestors=[]);
    raw = [x for x in w.ancestors if x != vid];
    return sorted(raw);
}

def dep_closure(g: KVOPGraph, vid: str) -> list[str] {
    anchor = _resolve(g, vid);
    if anchor is None { return []; }
    w = anchor spawn DepWalk(origin=vid, claimed={}, reached=[]);
    return sorted(w.reached);
}

def audit_reachable(g: KVOPGraph, start: str, target: str) -> bool {
    if _resolve(g, start) is None or _resolve(g, target) is None { return False; }
    if start == target { return True; }
    return target in dep_closure(g, start);
}

def has_dep_cycle(g: KVOPGraph) -> bool {
    for nd in [-->][?:Version] {
        w = nd spawn CycleProbe(claimed={}, stack=[], found=False);
        if w.found { return True; }
    }
    return False;
}

def audit_closure(g: KVOPGraph, vid: str) -> list[str] {
    if _resolve(g, vid) is None { return []; }
    scope: list[str] = [vid];
    for x in lineage_ancestors(g, vid) {
        if x not in scope { scope.append(x); }
    }
    for x in dep_closure(g, vid) {
        if x not in scope { scope.append(x); }
    }
    return sorted(scope);
}
