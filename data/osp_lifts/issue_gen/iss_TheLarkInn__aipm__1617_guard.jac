"""TheLarkInn/aipm#1617 — Build performance report: memoized crate lineage and feature-trim impact."""

node BuildUnit {
    has name: str;
    has seconds: float = 0.0;
    has is_build_script: bool = False;
}

edge GatedDep: BuildUnit --> BuildUnit {
    has gate: str = "";
}

edge LineageOf: BuildUnit --> BuildUnit {}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has trimmed: dict[str, bool] = {};
    has origin: str = "";

    can step with BuildUnit entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin { self.found.append(here.name); }
        nxt: list[BuildUnit] = [];
        for tgt in [here ->:GatedDep:->][?:BuildUnit] {
            for e in [edge here ->:GatedDep:-> tgt] {
                gt = e.gate;
                if gt and gt in self.trimmed { continue; }
                nxt.append(tgt);
            }
        }
        if nxt { visit nxt; }
    }
}

walker LineageClimb {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];
    has origin: str = "";

    can step with BuildUnit entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin { self.chain.append(here.name); }
        visit [->:LineageOf:->][?:BuildUnit];
    }
}

obj BuildReportGraph {
    has times: dict[str, float] = {};
    has build_script: dict[str, bool] = {};
    has gated_deps: dict[str, list[tuple[str, str]]] = {};
    has lineage: dict[str, str] = {};
    has _ancestor_memo: dict[str, list[str]] = {};
    has units: dict[str, BuildUnit] = {};
}

def _trimmed_map(features: list[str] | None) -> dict[str, bool] {
    out: dict[str, bool] = {};
    if features is None { return out; }
    for f in features { out[f] = True; }
    return out;
}

def _slow_key(row: tuple[str, float]) -> tuple[float, str] {
    return (-row[1], row[0]);
}

def load_build_report_graph(
    units: list[tuple[str, float, bool]],
    gated_edges: list[tuple[str, str, str]],
    lineage_edges: list[tuple[str, str]],
) -> BuildReportGraph {
    g = BuildReportGraph();
    for (name, secs, is_bs) in units {
        g.times[name] = secs;
        g.build_script[name] = is_bs;
        g.gated_deps.setdefault(name, []);
        if name not in g.units {
            nd = BuildUnit(name=name, seconds=secs, is_build_script=is_bs);
            root ++> nd;
            g.units[name] = nd;
        }
    }
    for (consumer, dep, gate) in gated_edges {
        if consumer in g.gated_deps and dep in g.times {
            g.gated_deps[consumer].append((dep, gate));
            c = g.units.get(consumer, None);
            d = g.units.get(dep, None);
            if c is not None and d is not None { c +>:GatedDep(gate=gate):+> d; }
        }
    }
    for (child, parent) in lineage_edges {
        if child in g.times {
            g.lineage[child] = parent;
            ch = g.units.get(child, None);
            pa = g.units.get(parent, None);
            if ch is not None and pa is not None { ch +>:LineageOf:+> pa; }
        }
    }
    return g;
}

def _reachable(g: BuildReportGraph, `root: str, trimmed: dict[str, bool]) -> dict[str, bool] {
    if `root not in g.times { return {}; }
    nd = g.units.get(`root, None);
    if nd is None { return {}; }
    w = nd spawn ReachWalk(claimed={}, found=[], trimmed=trimmed, origin=`root);
    out: dict[str, bool] = {};
    for nm in w.found { out[nm] = True; }
    return out;
}

def memo_ancestors(g: BuildReportGraph, unit: str) -> list[str] {
    if unit not in g.times { return []; }
    if unit in g._ancestor_memo { return g._ancestor_memo[unit]; }
    nd = g.units.get(unit, None);
    if nd is None { return []; }
    w = nd spawn LineageClimb(claimed={}, chain=[], origin=unit);
    out = sorted(w.chain);
    g._ancestor_memo[unit] = out;
    return out;
}

def transitive_build_deps(
    g: BuildReportGraph,
    `root: str,
    trimmed_features: list[str] | None = None,
) -> list[str] {
    reach = _reachable(g, `root, _trimmed_map(trimmed_features));
    out: list[str] = [];
    for nm in reach.keys() { out.append(nm); }
    return sorted(out);
}

def units_blocked_by_trim(
    g: BuildReportGraph,
    `root: str,
    trimmed_features: list[str],
) -> list[str] {
    if `root not in g.times { return []; }
    before = _reachable(g, `root, {});
    after = _reachable(g, `root, _trimmed_map(trimmed_features));
    out: list[str] = [];
    for nm in before.keys() {
        if nm not in after { out.append(nm); }
    }
    return sorted(out);
}

def trim_time_savings(
    g: BuildReportGraph,
    `root: str,
    trimmed_features: list[str],
) -> float {
    blocked = units_blocked_by_trim(g, `root, trimmed_features);
    total = 0.0;
    for u in blocked { total += g.times[u]; }
    return round(total, 1);
}

def build_script_hotspots(
    g: BuildReportGraph,
    threshold: float,
) -> list[tuple[str, float]] {
    rows: list[tuple[str, float]] = [];
    for name in g.times {
        if g.build_script.get(name, False) and g.times[name] >= threshold {
            rows.append((name, g.times[name]));
        }
    }
    return sorted(rows, key=_slow_key);
}

test "diamond gated revisit transitive closure" {
    g = load_build_report_graph(
        [("root", 0.0, False), ("left", 1.0, False), ("right", 1.0, False), ("join", 2.0, False)],
        [("root", "left", ""), ("root", "right", ""), ("left", "join", ""), ("right", "join", "")],
        [],
    );
    assert transitive_build_deps(g, "root") == ["join", "left", "right"];;
    assert transitive_build_deps(g, "join") == [];;
}

test "cyclic gated deps claim skip" {
    g = load_build_report_graph(
        [("root", 0.0, False), ("a", 1.0, False), ("b", 1.0, False), ("leaf", 2.0, False)],
        [("root", "a", ""), ("a", "b", ""), ("b", "a", ""), ("a", "leaf", "")],
        [],
    );
    assert transitive_build_deps(g, "root") == ["a", "b", "leaf"];;
    assert units_blocked_by_trim(g, "root", ["missing_gate"]) == [];;
}

test "unknown id tolerance" {
    g = load_build_report_graph(
        [("only", 1.0, False)],
        [("only", "ghost", "tls"), ("ghost", "only", ""), ("phantom", "only", "x")],
        [("ghost", "only"), ("only", "ghost")],
    );
    assert transitive_build_deps(g, "ghost") == [];;
    assert units_blocked_by_trim(g, "ghost", ["tls"]) == [];;
    assert memo_ancestors(g, "ghost") == [];;
    assert trim_time_savings(g, "ghost", ["tls"]) == 0.0;;
    assert transitive_build_deps(g, "only") == [];;
}

test "feature trim blocked units and savings" {
    g = load_build_report_graph(
        [("root", 0.0, False), ("keep", 1.0, False), ("trim_m", 2.0, False), ("trim_l", 3.0, False)],
        [("root", "keep", ""), ("root", "trim_m", "feat"), ("trim_m", "trim_l", "feat")],
        [],
    );
    assert units_blocked_by_trim(g, "root", ["feat"]) == ["trim_l", "trim_m"];;
    assert trim_time_savings(g, "root", ["feat"]) == 5.0;;
    assert transitive_build_deps(g, "root", ["feat"]) == ["keep"];;
    assert transitive_build_deps(g, "root", None) == ["keep", "trim_l", "trim_m"];;
    assert transitive_build_deps(g, "root", []) == ["keep", "trim_l", "trim_m"];;
}

test "lineage memo acyclic chain" {
    g = load_build_report_graph(
        [("leaf", 1.0, False), ("mid", 2.0, False), ("anc", 3.0, False)],
        [],
        [("leaf", "mid"), ("mid", "anc")],
    );
    assert memo_ancestors(g, "leaf") == ["anc", "mid"];;
    assert memo_ancestors(g, "leaf") == ["anc", "mid"];;
    assert memo_ancestors(g, "anc") == [];;
}

test "build script hotspots tiebreak and threshold" {
    g = load_build_report_graph(
        [("z_bs", 5.0, True), ("a_bs", 5.0, True), ("small", 1.0, True), ("plain", 9.0, False)],
        [],
        [],
    );
    assert build_script_hotspots(g, 5.0) == [("a_bs", 5.0), ("z_bs", 5.0)];;
    assert build_script_hotspots(g, 6.0) == [];;
}
