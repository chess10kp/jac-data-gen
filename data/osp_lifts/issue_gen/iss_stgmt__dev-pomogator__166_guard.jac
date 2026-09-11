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
test "layer_of maps id prefixes to layers" {
    assert layer_of("FR-7") == "fr";
    assert layer_of("AC-1") == "ac";
    assert layer_of("TASK-2") == "task";
    assert layer_of("TEST-3") == "test";
}

test "transitive impact across layers with depths and kinds" {
    # Cross-layer chain FR-7 <- AC-1/AC-2 <- SCN-1 (diamond, adversarial
    # edge order) <- TASK-2 <- FILE-9, TEST-3. Edge (from, to, kind).
    edges = [
        ["AC-2", "FR-7", "refs"],
        ["SCN-1", "AC-2", "covers"],
        ["AC-1", "FR-7", "refs"],
        ["SCN-1", "AC-1", "covers"],
        ["TASK-2", "SCN-1", "implements"],
        ["FILE-9", "TASK-2", "step-binding"],
        ["TEST-3", "TASK-2", "tested-by"],
    ];
    res = impact(edges, "FR-7");
    assert sorted(res.keys()) == ["AC-1", "AC-2", "FILE-9", "SCN-1", "TASK-2", "TEST-3"];
    assert res["AC-1"]["depth"] == 1 and res["AC-1"]["kind"] == "ac";
    assert res["AC-2"]["depth"] == 1 and res["AC-2"]["kind"] == "ac";
    assert res["SCN-1"]["depth"] == 2 and res["SCN-1"]["kind"] == "scn";
    assert res["TASK-2"]["depth"] == 3 and res["TASK-2"]["kind"] == "task";
    assert res["FILE-9"]["depth"] == 4 and res["FILE-9"]["kind"] == "file";
    assert res["TEST-3"]["depth"] == 4 and res["TEST-3"]["kind"] == "test";
}

test "one-hop oracle: find_refs equals depth-1 impact" {
    edges = [
        ["AC-2", "FR-7", "refs"],
        ["SCN-1", "AC-2", "covers"],
        ["AC-1", "FR-7", "refs"],
        ["SCN-1", "AC-1", "covers"],
        ["TASK-2", "SCN-1", "implements"],
        ["FILE-9", "TASK-2", "step-binding"],
        ["TEST-3", "TASK-2", "tested-by"],
    ];
    assert find_refs(edges, "FR-7") == ["AC-1", "AC-2"];
    one = impact(edges, "FR-7", 1);
    ids: list[str] = [];
    for sid in one.keys() { ids.append(sid); }
    assert sorted(ids) == find_refs(edges, "FR-7");
    assert find_refs(edges, "TASK-2") == ["FILE-9", "TEST-3"];
    assert find_refs(edges, "FR-404") == [];
}

test "depth caps include at the cap without expanding" {
    edges = [
        ["AC-2", "FR-7", "refs"],
        ["SCN-1", "AC-2", "covers"],
        ["AC-1", "FR-7", "refs"],
        ["SCN-1", "AC-1", "covers"],
        ["TASK-2", "SCN-1", "implements"],
        ["FILE-9", "TASK-2", "step-binding"],
        ["TEST-3", "TASK-2", "tested-by"],
    ];
    two = impact(edges, "FR-7", 2);
    assert sorted(two.keys()) == ["AC-1", "AC-2", "SCN-1"];
    assert two["SCN-1"]["depth"] == 2;
    assert impact(edges, "FR-7", 0) == {};
    one = impact(edges, "SCN-1", 1);
    assert one["TASK-2"]["depth"] == 1 and one["TASK-2"]["kind"] == "task";
}

test "byLayer grouping sorts per layer" {
    edges = [
        ["AC-2", "FR-7", "refs"],
        ["SCN-1", "AC-2", "covers"],
        ["AC-1", "FR-7", "refs"],
        ["SCN-1", "AC-1", "covers"],
        ["TASK-2", "SCN-1", "implements"],
        ["FILE-9", "TASK-2", "step-binding"],
        ["TEST-3", "TASK-2", "tested-by"],
    ];
    by = impact_by_layer(edges, "FR-7");
    assert by["ac"] == ["AC-1", "AC-2"];
    assert by["scn"] == ["SCN-1"];
    assert by["task"] == ["TASK-2"];
    assert by["file"] == ["FILE-9"];
    assert by["test"] == ["TEST-3"];
    by2 = impact_by_layer(edges, "SCN-1", 1);
    assert by2["task"] == ["TASK-2"];
}

test "shortest chain wins over a longer path" {
    asym = [["DEEP", "FR-7", "refs"], ["MID", "FR-7", "refs"], ["DEEP", "MID", "refs"]];
    res = impact(asym, "FR-7");
    assert res["MID"]["depth"] == 1;
    assert res["DEEP"]["depth"] == 1;
}

test "cycles terminate via the claim map" {
    cyc = [["T2", "T1", "refs"], ["T1", "T2", "refs"], ["T3", "T2", "refs"]];
    res = impact(cyc, "T1");
    assert sorted(res.keys()) == ["T2", "T3"];
    assert res["T2"]["depth"] == 1 and res["T2"]["kind"] == "t2";
    assert res["T3"]["depth"] == 2 and res["T3"]["kind"] == "t3";
}

test "unknown root has empty blast radius" {
    edges = [["AC-1", "FR-7", "refs"]];
    assert impact(edges, "FR-404") == {};
}
