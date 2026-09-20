"""maui314159/navigatsql#5 — construct concept nodes + custom:uses_* edges in kggraph."""

node KgGraph {
    has pair_tag: dict[str, str] = {};
}

node Definition {
    has did: str;
}

node Construct {
    has cid: str;
    has kind: str = "construct";
}

edge Uses {
    has tag: str = "";
}

walker FindNodeWalker {
    has target: str;
    has hit: object | None = None;
    has claimed: dict[str, bool] = {};

    can scan_kg with KgGraph entry {
        print ["find_kg", self.target];
        kids: list = [here -->.];
        visit :0: kids;
    }

    can scan_def with Definition entry {
        if here.did in self.claimed { skip; }
        self.claimed[here.did] = True;
        print ["find_def", here.did];
        if here.did == self.target {
            self.hit = here;
            disengage;
        }
        kids: list = [here -->.];
        if kids { visit :0: kids; } else { disengage; }
    }

    can scan_con with Construct entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print ["find_con", here.cid];
        if here.cid == self.target {
            self.hit = here;
            disengage;
        }
        kids: list = [here -->.];
        if kids { visit :0: kids; } else { disengage; }
    }
}

walker NeighborsInWalker {
    has target: str;
    has edge_kind: str = "";
    has kg_ref: KgGraph;
    has results: list[str] = [];
    has claimed: dict[str, bool] = {};

    can walk_kg with KgGraph entry {
        print ["nin_kg", self.target];
        kids: list = [here -->.];
        visit :0: kids;
    }

    can walk_def with Definition entry {
        if here.did in self.claimed { skip; }
        self.claimed[here.did] = True;
        print ["nin_def", here.did];
        kids: list = [here -->.];
        if kids { visit :0: kids; } else { disengage; }
    }

    can walk_con with Construct entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print ["nin_con", here.cid];
        if here.cid == self.target {
            preds: list = [here <-:Uses:<-];
            for pred in preds {
                if pred is Definition {
                    pd = pred as Definition;
                    pair_key = pd.did + "|" + here.cid;
                    include = True;
                    if self.edge_kind != "" {
                        t = self.kg_ref.pair_tag[pair_key];
                        if t != self.edge_kind { include = False; }
                    }
                    if include { self.results.append(pd.did); }
                }
            }
            disengage;
        }
        kids: list = [here -->.];
        if kids { visit :0: kids; } else { disengage; }
    }
}

walker EmitWalker {
    has claimed: dict[str, bool] = {};
    has nodes_out: list[dict] = [];
    has edges_out: list[dict] = [];
    has edge_seen: dict[str, bool] = {};

    can emit_kg with KgGraph entry {
        print ["emit_kg"];
        kids: list = [here -->.];
        visit :0: kids;
    }

    can emit_def with Definition entry {
        if here.did in self.claimed { skip; }
        self.claimed[here.did] = True;
        print ["emit_def", here.did];
        nd: dict = {};
        nd["id"] = here.did;
        nd["kind"] = "definition";
        self.nodes_out.append(nd);
        outs: list = [here ->:Uses:->];
        for con in outs {
            if con is Construct {
                cc = con as Construct;
                ek = here.did + "|" + cc.cid;
                if ek not in self.edge_seen {
                    self.edge_seen[ek] = True;
                    ed: dict = {};
                    ed["from"] = here.did;
                    ed["to"] = cc.cid;
                    for u in [here ->:Uses:->] {
                        if u is cc {
                            ed["tag"] = [here ->:Uses:+> cc][0].tag;
                        }
                    }
                    self.edges_out.append(ed);
                }
            }
        }
        kids: list = [here -->.];
        if kids { visit :0: kids; } else { disengage; }
    }

    can emit_con with Construct entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print ["emit_con", here.cid];
        nd: dict = {};
        nd["id"] = here.cid;
        nd["kind"] = here.kind;
        self.nodes_out.append(nd);
        kids: list = [here -->.];
        if kids { visit :0: kids; } else { disengage; }
    }
}

def construct_vocab -> dict[str, list[str]] {
    vocab: dict[str, list[str]] = {};
    vocab["dynamic_sql"] = ["construct:dynamic_sql", "custom:uses_dynamic_sql"];
    vocab["cursor"] = ["construct:cursor", "custom:uses_cursor"];
    vocab["recursive_cte"] = ["construct:recursive_cte", "custom:uses_recursive_cte"];
    vocab["merge_statement"] = ["construct:merge_statement", "custom:uses_merge_statement"];
    vocab["nolock_hint"] = ["construct:nolock_hint", "custom:uses_nolock_hint"];
    return vocab;
}

def build_kg(definitions: list[dict]) -> KgGraph {
    kg = KgGraph();
    root ++> kg;
    vocab = construct_vocab();
    construct_cache: dict[str, Construct] = {};
    for spec in definitions {
        did: str = spec["did"] as str;
        defn = Definition(did=did);
        kg ++> defn;
        uses_list: list[str] = spec["uses"] as list[str];
        for use_name in uses_list {
            pair: list[str] = vocab[use_name] as list[str];
            cid: str = pair[0];
            etag: str = pair[1];
            pair_key: str = defn.did + "|" + cid;
            if pair_key in kg.pair_tag { continue; }
            if cid in construct_cache {
                con = construct_cache[cid];
            } else {
                con = Construct(cid=cid);
                construct_cache[cid] = con;
                kg ++> con;
            }
            ue: Uses = defn +>:Uses:+> con;
            ue.tag = etag;
            kg.pair_tag[pair_key] = etag;
        }
    }
    return kg;
}

def find_node(kg: KgGraph, node_id: str) -> object | None {
    w = kg spawn FindNodeWalker(target=node_id);
    return w.hit;
}

def neighbors_in(kg: KgGraph, node_id: str, edge_kind: str | None = None) -> list[str] {
    ek: str = "";
    if edge_kind is not None { ek = edge_kind; }
    w = kg spawn NeighborsInWalker(target=node_id, edge_kind=ek, kg_ref=kg);
    return sorted(w.results);
}

def emit_kggraph(kg: KgGraph) -> dict {
    w = kg spawn EmitWalker(claimed={});
    nodes_sorted: list[dict] = sorted(w.nodes_out, key=lambda x: x["id"]);
    edges_sorted: list[dict] = sorted(
        w.edges_out, key=lambda x: x["from"] + "|" + x["to"] + "|" + x["tag"]
    );
    out: dict = {};
    out["nodes"] = nodes_sorted;
    out["edges"] = edges_sorted;
    return out;
}

test "construct_vocab_covers_issue_table" {
    vocab = construct_vocab();
    assert "dynamic_sql" in vocab;
    assert vocab["recursive_cte"][0] == "construct:recursive_cte";
    assert vocab["recursive_cte"][1] == "custom:uses_recursive_cte";
    assert len(vocab) == 5;
}

test "neighbors_in_dynamic_sql_sorted" {
    specs: list[dict] = [];
    s1: dict = {}; s1["did"] = "dbo.proc_A"; s1["uses"] = ["dynamic_sql"];
    s2: dict = {}; s2["did"] = "dbo.proc_B"; s2["uses"] = ["dynamic_sql", "cursor"];
    specs.append(s1); specs.append(s2);
    kg = build_kg(specs);
    got = neighbors_in(kg, "construct:dynamic_sql", None);
    assert got == ["dbo.proc_A", "dbo.proc_B"];
}

test "edge_kind_filter_excludes_cursor" {
    specs: list[dict] = [];
    s1: dict = {}; s1["did"] = "dbo.proc_B"; s1["uses"] = ["dynamic_sql", "cursor"];
    specs.append(s1);
    kg = build_kg(specs);
    got = neighbors_in(kg, "construct:dynamic_sql", "custom:uses_dynamic_sql");
    assert got == ["dbo.proc_B"];
    miss = neighbors_in(kg, "construct:cursor", "custom:uses_dynamic_sql");
    assert miss == [];
}

test "unknown_id_returns_none" {
    specs: list[dict] = [];
    s1: dict = {}; s1["did"] = "dbo.only"; s1["uses"] = ["merge_statement"];
    specs.append(s1);
    kg = build_kg(specs);
    assert find_node(kg, "construct:does_not_exist") is None;
    assert find_node(kg, "dbo.only") is not None;
}

test "diamond_revisit_dedup_one_edge_per_pair" {
    specs: list[dict] = [];
    s1: dict = {};
    s1["did"] = "dbo.diamond";
    s1["uses"] = ["recursive_cte", "recursive_cte", "recursive_cte"];
    specs.append(s1);
    kg = build_kg(specs);
    out = emit_kggraph(kg);
    assert len(out["edges"]) == 1;
    assert out["edges"][0]["from"] == "dbo.diamond";
    assert out["edges"][0]["to"] == "construct:recursive_cte";
    assert out["edges"][0]["tag"] == "custom:uses_recursive_cte";
    nbs = neighbors_in(kg, "construct:recursive_cte", None);
    assert nbs == ["dbo.diamond"];
}

test "emit_byte_deterministic_multiset" {
    specs: list[dict] = [];
    a: dict = {}; a["did"] = "dbo.zed"; a["uses"] = ["nolock_hint"];
    b: dict = {}; b["did"] = "dbo.aaa"; b["uses"] = ["cursor"];
    specs.append(a); specs.append(b);
    kg = build_kg(specs);
    out = emit_kggraph(kg);
    ids: list[str] = [];
    for n in out["nodes"] { ids.append(n["id"] as str); }
    assert ids == sorted(ids);
    assert len(out["nodes"]) == 4;
    assert len(out["edges"]) == 2;
}
