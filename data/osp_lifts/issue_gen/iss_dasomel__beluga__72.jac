"""dasomel/beluga#72 — Silver/Gold transformation DAG and engine selection."""

node Transform {
    has tid: str;
}

edge Depends {}

walker UpstreamWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Transform entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        if here.tid != self.origin { self.found.append(here.tid); }
        visit [->:Depends:->][?:Transform];
    }
}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Transform entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        if here.tid != self.origin { self.found.append(here.tid); }
        visit [<-:Depends:<-][?:Transform];
    }
}

walker LineagePathWalk {
    has target: str = "";
    has max_depth: int = 12;
    has trail: list[str] = [];
    has paths: list[list[str]] = [];

    can step with Transform entry {
        if here.tid in self.trail { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.tid);
        if here.tid == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        if len(nt) >= self.max_depth { skip; }
        kids = [here ->:Depends:->][?:Transform];
        nms: list[str] = [];
        for n in kids { nms.append(n.tid); }
        for nm in sorted(nms) {
            for n in kids {
                if n.tid == nm {
                    n spawn LineagePathWalk(
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

obj TransformationGraph {
    has transforms: dict[str, dict[str, object]] = {};
    has deps: dict[str, list[str]] = {};
    has reverse: dict[str, list[str]] = {};
    has units: dict[str, object] = {};
}

def select_engine(
    category: str,
    *,
    stateful: bool = False,
    bounded: bool = False,
    scale: str = "medium",
) -> str {
    if stateful or category == "streaming" { return "flink"; }
    if bounded or category == "lightweight_sql" { return "duckdb"; }
    if category == "gold_publish" { return "trino"; }
    if scale == "large" and category in ("batch_sql", "aggregation", "enrichment") {
        return "trino";
    }
    return "airflow_sql";
}

def load_transformation_graph(
    transforms: list[tuple[str, str, str, dict[str, object]]],
    edges: list[tuple[str, str]],
) -> TransformationGraph {
    g = TransformationGraph();
    for (tid, layer, category, attrs) in transforms {
        spec: dict[str, object] = {"layer": layer, "category": category, **attrs};
        spec["engine"] = select_engine(
            category,
            stateful=bool(attrs.get("stateful", False)),
            bounded=bool(attrs.get("bounded", False)),
            scale=str(attrs.get("scale", "medium")),
        );
        g.transforms[tid] = spec;
        g.deps.setdefault(tid, []);
        g.reverse.setdefault(tid, []);
        nd = Transform(tid=tid);
        root ++> nd;
        g.units[tid] = nd;
    }
    for (consumer, upstream) in edges {
        if consumer in g.transforms and upstream in g.transforms {
            g.deps[consumer].append(upstream);
            g.reverse[upstream].append(consumer);
            c_raw = g.units.get(consumer, None);
            u_raw = g.units.get(upstream, None);
            if c_raw is not None and u_raw is not None {
                c = c_raw as Transform;
                u = u_raw as Transform;
                c +>:Depends:+> u;
            }
        }
    }
    return g;
}

def upstream_transforms(g: TransformationGraph, transform_id: str) -> list[str] {
    if transform_id not in g.transforms { return []; }
    raw = g.units.get(transform_id, None);
    if raw is None { return []; }
    nd = raw as Transform;
    w = nd spawn UpstreamWalk(claimed={}, found=[], origin=transform_id);
    return sorted(w.found);
}

def downstream_consumers(g: TransformationGraph, transform_id: str) -> list[str] {
    if transform_id not in g.transforms { return []; }
    raw = g.units.get(transform_id, None);
    if raw is None { return []; }
    nd = raw as Transform;
    w = nd spawn DownstreamWalk(claimed={}, found=[], origin=transform_id);
    return sorted(w.found);
}

def lineage_paths(
    g: TransformationGraph,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]] {
    if source not in g.transforms or target not in g.transforms { return []; }
    raw = g.units.get(source, None);
    if raw is None { return []; }
    nd = raw as Transform;
    w = nd spawn LineagePathWalk(
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

def engine_for_transform(g: TransformationGraph, transform_id: str) -> str | None {
    spec = g.transforms.get(transform_id, None);
    if spec is None { return None; }
    return str(spec["engine"]);
}

test "engine selection matrix" {
    assert select_engine("streaming") == "flink";
    assert select_engine("batch_sql", stateful=True) == "flink";
    assert select_engine("lightweight_sql") == "duckdb";
    assert select_engine("batch_sql", bounded=True) == "duckdb";
    assert select_engine("gold_publish") == "trino";
    assert select_engine("batch_sql", scale="large") == "trino";
    assert select_engine("aggregation", scale="large") == "trino";
    assert select_engine("batch_sql") == "airflow_sql";
}

test "graph load upstream downstream closure" {
    g = load_transformation_graph(
        [
            ("raw", "bronze", "ingest", {}),
            ("clean", "silver", "batch_sql", {}),
            ("agg", "silver", "aggregation", {"scale": "large"}),
            ("pub", "gold", "gold_publish", {}),
        ],
        [
            ("clean", "raw"),
            ("agg", "clean"),
            ("pub", "agg"),
        ],
    );
    assert engine_for_transform(g, "agg") == "trino";
    assert engine_for_transform(g, "clean") == "airflow_sql";
    assert engine_for_transform(g, "missing") is None;
    assert upstream_transforms(g, "pub") == ["agg", "clean", "raw"];
    assert upstream_transforms(g, "raw") == [];
    assert downstream_consumers(g, "raw") == ["agg", "clean", "pub"];
    assert downstream_consumers(g, "pub") == [];
}

test "lineage paths depth and unknown ids" {
    g = load_transformation_graph(
        [
            ("a", "silver", "batch_sql", {}),
            ("b", "silver", "batch_sql", {}),
            ("c", "silver", "batch_sql", {}),
            ("d", "gold", "gold_publish", {}),
        ],
        [
            ("d", "b"),
            ("d", "c"),
            ("b", "a"),
            ("c", "a"),
        ],
    );
    assert lineage_paths(g, "d", "a") == [
        ["d", "b", "a"],
        ["d", "c", "a"],
    ];
    assert lineage_paths(g, "d", "a", max_depth=2) == [];
    assert lineage_paths(g, "x", "a") == [];
    assert lineage_paths(g, "a", "d") == [];
}

test "cycle diamond upstream revisit policy" {
    g = load_transformation_graph(
        [
            ("hub", "silver", "batch_sql", {}),
            ("left", "silver", "batch_sql", {}),
            ("right", "silver", "batch_sql", {}),
            ("join", "gold", "gold_publish", {}),
        ],
        [
            ("join", "left"),
            ("join", "right"),
            ("left", "hub"),
            ("right", "hub"),
        ],
    );
    assert upstream_transforms(g, "join") == ["hub", "left", "right"];
    assert lineage_paths(g, "join", "hub") == [
        ["join", "left", "hub"],
        ["join", "right", "hub"],
    ];
}
