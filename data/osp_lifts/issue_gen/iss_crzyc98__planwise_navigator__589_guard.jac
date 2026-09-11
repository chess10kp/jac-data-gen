"""crzyc98/planwise_navigator#589 — dbt mart pipeline orphan audit.

The orphaned fct_policy_optimization mart depends on demo variables and sits
outside the production build selection. Hand-rolled dependency adjacency,
reverse referencer index, and deque reach walks over the workflow DAG.
"""

node MartModel {
    has name: str;
    has kind: str;
    has tags: list[str] = [];
}

edge Depends: MartModel --> MartModel {}

walker UpstreamReachWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with MartModel entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin {
            self.found.append(here.name);
        }
        visit [->:Depends:->][?:MartModel];
    }
}

walker DownstreamReachWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with MartModel entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin {
            self.found.append(here.name);
        }
        visit [<-:Depends:<-][?:MartModel];
    }
}

obj MartDag {
    has models: dict[str, MartModel] = {};
    has kinds: dict[str, str] = {};
    has tags: dict[str, list[str]] = {};
}

def load_mart_dag(
    models: list[tuple[str, str, list[str]]],
    dependencies: list[tuple[str, str]],
) -> MartDag {
    dag = MartDag();
    for (name, kind, tag_list) in models {
        nd = MartModel(name=name, kind=kind, tags=tag_list);
        root ++> nd;
        dag.models[name] = nd;
        dag.kinds[name] = kind;
        dag.tags[name] = tag_list;
    }
    for (model, upstream) in dependencies {
        m = dag.models.get(model, None);
        u = dag.models.get(upstream, None);
        if m is not None and u is not None { m +>:Depends:+> u; }
    }
    return dag;
}

def upstream_reach(dag: MartDag, model: str) -> list[str] {
    nd = dag.models.get(model, None);
    if nd is None { return []; }
    w = nd spawn UpstreamReachWalk(claimed={}, found=[], origin=model);
    return sorted(w.found);
}

def downstream_reach(dag: MartDag, model: str) -> list[str] {
    nd = dag.models.get(model, None);
    if nd is None { return []; }
    w = nd spawn DownstreamReachWalk(claimed={}, found=[], origin=model);
    return sorted(w.found);
}

def direct_referencers(dag: MartDag, target: str) -> list[str] {
    if target not in dag.models { return []; }
    nd = dag.models[target];
    kids = [nd <-:Depends:<-][?:MartModel];
    return sorted([r.name for r in kids]);
}

def production_closure(dag: MartDag, selection_roots: list[str]) -> list[str] {
    included: dict[str, bool] = {};
    for sel in selection_roots {
        if sel not in dag.models { continue; }
        included[sel] = True;
        for nm in upstream_reach(dag, sel) {
            included[nm] = True;
        }
    }
    out: list[str] = [];
    for k in included.keys() { out.append(k); }
    return sorted(out);
}

def orphan_facts(dag: MartDag, selection_roots: list[str]) -> list[str] {
    live: dict[str, bool] = {};
    for nm in production_closure(dag, selection_roots) { live[nm] = True; }
    out: list[str] = [];
    for nm in dag.models {
        if dag.kinds.get(nm, "") == "fact" and not live.get(nm, False) {
            out.append(nm);
        }
    }
    return sorted(out);
}

test "diamond revisit upstream reach" {
    dag = load_mart_dag(
        [("apex", "dim", []), ("left", "stg", []), ("right", "stg", []), ("join", "fact", [])],
        [("join", "left"), ("join", "right"), ("left", "apex"), ("right", "apex")],
    );
    assert upstream_reach(dag, "join") == ["apex", "left", "right"];
    assert upstream_reach(dag, "apex") == [];
}

test "diamond revisit downstream reach" {
    dag = load_mart_dag(
        [("hub", "dim", []), ("mid_a", "stg", []), ("mid_b", "stg", []), ("leaf", "fact", [])],
        [("mid_a", "hub"), ("mid_b", "hub"), ("leaf", "mid_a"), ("leaf", "mid_b")],
    );
    assert downstream_reach(dag, "hub") == ["leaf", "mid_a", "mid_b"];
    assert downstream_reach(dag, "leaf") == [];
}

test "unknown id tolerance" {
    dag = load_mart_dag([("only", "fact", ["prod"])], []);
    assert upstream_reach(dag, "missing") == [];
    assert downstream_reach(dag, "missing") == [];
    assert direct_referencers(dag, "missing") == [];
    assert production_closure(dag, ["missing", "only"]) == ["only"];
    assert orphan_facts(dag, ["missing"]) == ["only"];
}

test "cycle reach terminates without disengage" {
    dag = load_mart_dag(
        [("a", "fact", []), ("b", "stg", []), ("c", "stg", [])],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert upstream_reach(dag, "a") == ["b", "c"];
    assert downstream_reach(dag, "c") == ["a", "b"];
}

test "ignored dependency endpoints" {
    dag = load_mart_dag(
        [("dim_x", "dim", []), ("fact_y", "fact", []), ("stg_z", "stg", [])],
        [("fact_y", "dim_x"), ("fact_y", "ghost"), ("phantom", "stg_z")],
    );
    assert direct_referencers(dag, "dim_x") == ["fact_y"];
    assert direct_referencers(dag, "stg_z") == [];
    assert upstream_reach(dag, "fact_y") == ["dim_x"];
}

test "orphan facts and overlapping production closure" {
    dag = load_mart_dag(
        [
            ("prod_root", "fact", ["prod"]),
            ("shared_dim", "dim", []),
            ("live_fact", "fact", ["prod"]),
            ("orphan_fact", "fact", []),
            ("stg_only", "stg", []),
        ],
        [
            ("prod_root", "shared_dim"),
            ("live_fact", "shared_dim"),
            ("stg_only", "shared_dim"),
        ],
    );
    assert production_closure(dag, ["prod_root", "live_fact"]) == ["live_fact", "prod_root", "shared_dim"];
    assert orphan_facts(dag, ["prod_root"]) == ["live_fact", "orphan_fact"];
    assert production_closure(dag, []) == [];
    assert orphan_facts(dag, []) == ["live_fact", "orphan_fact", "prod_root"];
}

test "diamond revisit upstream reach" {
    dag = load_mart_dag(
        [("apex", "dim", []), ("left", "stg", []), ("right", "stg", []), ("join", "fact", [])],
        [("join", "left"), ("join", "right"), ("left", "apex"), ("right", "apex")],
    );
    assert upstream_reach(dag, "join") == ["apex", "left", "right"];
    assert upstream_reach(dag, "apex") == [];
}

test "diamond revisit downstream reach" {
    dag = load_mart_dag(
        [("hub", "dim", []), ("mid_a", "stg", []), ("mid_b", "stg", []), ("leaf", "fact", [])],
        [("mid_a", "hub"), ("mid_b", "hub"), ("leaf", "mid_a"), ("leaf", "mid_b")],
    );
    assert downstream_reach(dag, "hub") == ["leaf", "mid_a", "mid_b"];
    assert downstream_reach(dag, "leaf") == [];
}

test "unknown id tolerance" {
    dag = load_mart_dag([("only", "fact", ["prod"])], []);
    assert upstream_reach(dag, "missing") == [];
    assert downstream_reach(dag, "missing") == [];
    assert direct_referencers(dag, "missing") == [];
    assert production_closure(dag, ["missing", "only"]) == ["only"];
    assert orphan_facts(dag, ["missing"]) == ["only"];
}

test "cycle reach terminates without disengage" {
    dag = load_mart_dag(
        [("a", "fact", []), ("b", "stg", []), ("c", "stg", [])],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert upstream_reach(dag, "a") == ["b", "c"];
    assert downstream_reach(dag, "c") == ["a", "b"];
}

test "ignored dependency endpoints" {
    dag = load_mart_dag(
        [("dim_x", "dim", []), ("fact_y", "fact", []), ("stg_z", "stg", [])],
        [("fact_y", "dim_x"), ("fact_y", "ghost"), ("phantom", "stg_z")],
    );
    assert direct_referencers(dag, "dim_x") == ["fact_y"];
    assert direct_referencers(dag, "stg_z") == [];
    assert upstream_reach(dag, "fact_y") == ["dim_x"];
}

test "orphan facts and overlapping production closure" {
    dag = load_mart_dag(
        [
            ("prod_root", "fact", ["prod"]),
            ("shared_dim", "dim", []),
            ("live_fact", "fact", ["prod"]),
            ("orphan_fact", "fact", []),
            ("stg_only", "stg", []),
        ],
        [
            ("prod_root", "shared_dim"),
            ("live_fact", "shared_dim"),
            ("stg_only", "shared_dim"),
        ],
    );
    assert production_closure(dag, ["prod_root", "live_fact"]) == ["live_fact", "prod_root", "shared_dim"];
    assert orphan_facts(dag, ["prod_root"]) == ["live_fact", "orphan_fact"];
    assert production_closure(dag, []) == [];
    assert orphan_facts(dag, []) == ["live_fact", "orphan_fact", "prod_root"];
}
