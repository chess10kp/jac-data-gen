"""Forward change-impact analysis, lifted to OSP.

Specs become Spec nodes (layer kind on the node), reference triples become
typed Depends edges carrying the edge kind, and the manual stack walk with
its visited-depth map becomes an ImpactWalk over reverse Depends edges
(``who depends on me``) -- the claim map is the cycle policy, the depth map
carries each dependent's first-arrival chain depth, and the depth cap is
domain logic kept explicit (record the node, return before expanding).
``find_refs`` stays the one-hop oracle, now a depth-1 impact.
Ref: stgmt/dev-pomogator#166
"""

node Spec {
    has id: str;
    has kind: str;
}
edge Depends {
    has kind: str;
}

"""Layer of a spec id: 'FR-7' -> 'fr', 'TASK-3' -> 'task'."""
def layer_of(spec_id: str) -> str {
    parts: list[str] = spec_id.split("-", 1);
    return parts[0].lower();
}

"""Loader handle: spec ids resolve through this lookup map."""
obj SpecGraph {
    has specs: dict[str, Spec];

    def resolve(sid: str) -> Spec | None {
        return self.specs.get(sid);
    }
}

"""Deterministic fresh-graph builder from a [(from, to, kind)] edge list."""
def load_sg(edges: list[list[str]]) -> SpecGraph {
    sg = SpecGraph(specs={});
    ids: set[str] = set();
    for e in edges {
        ids.add(e[0]);
        ids.add(e[1]);
    }
    for sid in ids {
        sp = Spec(id=sid, kind=layer_of(sid));
        root ++> sp;
        sg.specs[sid] = sp;
    }
    for e in edges {
        src = sg.resolve(e[0]);
        dst = sg.resolve(e[1]);
        if src is None { continue; }
        if dst is None { continue; }
        src +>:Depends(kind=e[2]):+> dst;
    }
    return sg;
}

walker ImpactWalk {
    has claimed: dict[str, bool] = {};
    has depths: dict[str, int] = {};
    has found: list[str] = [];
    has max_depth: int | None = None;

    can step with Spec entry {
        # Cycle policy: one arrival per spec regardless of path count.
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        d = self.depths.get(here.id);
        if d is None { d = 0; }
        self.found.append(here.id);
        # Depth cap (domain rule): the node is recorded, not expanded.
        if self.max_depth is not None {
            if d >= self.max_depth { return; }
        }
        # First-arrival depth for dependents (reverse: who depends on me).
        deps: list[Spec] = [here <-:Depends:<-];
        for dep in deps {
            if dep.id in self.depths { continue; }
            self.depths[dep.id] = d + 1;
        }
        visit [<-:Depends:<-];
    }
}

"""Transitive forward change-impact (blast radius) of ``spec_id``."""
def impact(edges: list[list[str]], spec_id: str, max_depth: int | None = None) -> dict {
    sg = load_sg(edges);
    r = sg.resolve(spec_id);
    if r is None { return {}; }
    w = r spawn ImpactWalk(claimed={}, depths={}, found=[], max_depth=max_depth);
    out: dict = {};
    for sid in w.found {
        if sid == spec_id { continue; }
        dv = w.depths.get(sid);
        if dv is None { dv = 0; }
        out[sid] = {"depth": dv, "kind": layer_of(sid)};
    }
    return out;
}

"""One-hop answer: ids that directly reference ``spec_id`` (sorted)."""
def find_refs(edges: list[list[str]], spec_id: str) -> list[str] {
    one: dict = impact(edges, spec_id, 1);
    ids: list[str] = [];
    for sid in one.keys() { ids.append(sid); }
    return sorted(ids);
}

"""Impact of ``spec_id`` grouped by layer (the report's byLayer view)."""
def impact_by_layer(edges: list[list[str]], spec_id: str, max_depth: int | None = None) -> dict {
    imp: dict = impact(edges, spec_id, max_depth);
    by: dict = {};
    for sid in imp.keys() {
        info: dict = imp[sid];
        k = info["kind"];
        if k in by {
            by[k].append(sid);
        } else {
            by[k] = [sid];
        }
    }
    out: dict = {};
    for k in by.keys() { out[k] = sorted(by[k]); }
    return out;
}
