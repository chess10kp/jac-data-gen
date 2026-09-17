# stSoftwareAU/NEAT-AI-core#688 — recursively splice IDENTITY neurons after IF rewrite.

node Neuron {
    has cid: str;
    has kind: str;
    has bias: float = 0.0;
}

edge Synapse {
    has weight: float = 1.0;
}

def new_creature() -> Neuron {
    graph_root = Neuron(cid="__root__", kind="root", bias=0.0);
    root ++> graph_root;
    return graph_root;
}

def add_neuron(graph_root: Neuron, cid: str, kind: str, bias: float = 0.0) -> Neuron {
    nd = Neuron(cid=cid, kind=kind, bias=bias);
    graph_root ++> nd;
    return nd;
}

def connect_neurons(src: Neuron, tgt: Neuron, weight: float) {
    e = src +>:Synapse:+> tgt;
    e.weight = weight;
}

def locate_neuron(graph_root: Neuron, cid: str) -> Neuron | None {
    wk = graph_root spawn SeekNeuron(target=cid, claimed={});
    return wk.res;
}

walker SeekNeuron {
    has target: str;
    has claimed: dict[str, bool] = {};
    has res: Neuron | None = None;
    can step with Neuron entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.target {
            self.res = here;
            print ["seek", here.cid];
            disengage;
        }
        kids: list[Neuron] = [here ->:Synapse:->][?:Neuron];
        for kid in kids {
            visit :0: [kid];
        }
    }
}

walker FindSpliceable {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];
    can step with Neuron entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        ins: list[Neuron] = [<-:Synapse:<- here][?:Neuron];
        outs: list[Neuron] = [here ->:Synapse:->][?:Neuron];
        if here.kind == "identity" and len(ins) > 0 and len(outs) > 0 {
            self.ids.append(here.cid);
            print ["spliceable", here.cid];
        }
        kids: list[Neuron] = [here ->:Synapse:->][?:Neuron];
        for kid in kids {
            visit :0: [kid];
        }
        backs: list[Neuron] = [<-:Synapse:<- here][?:Neuron];
        for back in backs {
            visit :0: [back];
        }
    }
}

def collect_spliceable(graph_root: Neuron) -> list[str] {
    wk = graph_root spawn FindSpliceable(claimed={});
    out: list[str] = sorted(wk.ids);
    return out;
}

def edge_weight(src: Neuron, tgt: Neuron) -> float {
    total: float = 0.0;
    es: list[Synapse] = [src ->:Synapse:-> tgt][?:Synapse];
    for e in es {
        total = total + e.weight;
    }
    return total;
}

def set_edge_weight(src: Neuron, tgt: Neuron, val: float) {
    es: list[Synapse] = [src ->:Synapse:-> tgt][?:Synapse];
    if len(es) > 0 {
        es[0].weight = val;
    } else {
        e = src +>:Synapse:+> tgt;
        e.weight = val;
    }
}

def splice_identity_node(graph_root: Neuron, nid: str) -> bool {
    nd = locate_neuron(graph_root, nid);
    if nd is None {
        return False;
    }
    if nd.kind != "identity" {
        return False;
    }
    in_ns: list[Neuron] = [<-:Synapse:<- nd][?:Neuron];
    out_ns: list[Neuron] = [nd ->:Synapse:->][?:Neuron];
    if len(in_ns) == 0 or len(out_ns) == 0 {
        return False;
    }
    in_ws: list[float] = [];
    for s in in_ns {
        syn: list[Synapse] = [s ->:Synapse:-> nd][?:Synapse];
        wi: float = 0.0;
        for sy in syn {
            wi = wi + sy.weight;
        }
        in_ws.append(wi);
    }
    out_ws: list[float] = [];
    for t in out_ns {
        syn2: list[Synapse] = [nd ->:Synapse:-> t][?:Synapse];
        wo: float = 0.0;
        for sy2 in syn2 {
            wo = wo + sy2.weight;
        }
        out_ws.append(wo);
    }
    nbias: float = nd.bias;
    ii: int = 0;
    for s in in_ns {
        wi2: float = in_ws[ii];
        jj: int = 0;
        for t in out_ns {
            wo2: float = out_ws[jj];
            prod: float = wi2 * wo2;
            old: float = edge_weight(s, t);
            set_edge_weight(s, t, old + prod);
            t.bias = t.bias + nbias * wo2;
            jj = jj + 1;
        }
        ii = ii + 1;
    }
    out_syns: list[Synapse] = [nd ->:Synapse:->][?:Synapse];
    for sy3 in out_syns {
        destroy sy3;
    }
    in_syns: list[Synapse] = [<-:Synapse:<- nd][?:Synapse];
    for sy4 in in_syns {
        destroy sy4;
    }
    destroy nd;
    return True;
}

def splice_identity_neurons(graph_root: Neuron, enabled: bool = True) -> dict {
    removed: list[str] = [];
    cascade: list[str] = [];
    if not enabled {
        out0: dict[str, list[str]] = {};
        out0["removed"] = removed;
        out0["cascade"] = cascade;
        return out0;
    }
    changed: bool = True;
    while changed {
        changed = False;
        ids: list[str] = collect_spliceable(graph_root);
        for nid in ids {
            if splice_identity_node(graph_root, nid) {
                removed.append(nid);
                cascade.append(nid);
                changed = True;
            }
        }
    }
    removed = sorted(removed);
    cascade = sorted(cascade);
    out1: dict[str, list[str]] = {};
    out1["removed"] = removed;
    out1["cascade"] = cascade;
    return out1;
}

def prune_neuron(graph_root: Neuron, neuron_id: str, splice_enabled: bool = True) -> dict {
    nd = locate_neuron(graph_root, neuron_id);
    if nd is None {
        bad: dict[str, bool | list[str]] = {};
        bad["ok"] = False;
        bad["removed_neurons"] = [];
        bad["cascade_neurons"] = [];
        return bad;
    }
    if nd.kind == "if" {
        nd.kind = "identity";
    } else {
        out_syns: list[Synapse] = [nd ->:Synapse:->][?:Synapse];
        for sy in out_syns {
            destroy sy;
        }
        in_syns: list[Synapse] = [<-:Synapse:<- nd][?:Synapse];
        for sy2 in in_syns {
            destroy sy2;
        }
        destroy nd;
    }
    outcome = splice_identity_neurons(graph_root, splice_enabled);
    good: dict[str, bool | list[str]] = {};
    good["ok"] = True;
    good["removed_neurons"] = [neuron_id];
    good["cascade_neurons"] = outcome["cascade"];
    return good;
}

test "locate_found" {
    g = new_creature();
    n = add_neuron(g, "x", "hidden");
    f = locate_neuron(g, "x");
    assert f.cid == "x";
}

test "splice_chain" {
    g = new_creature();
    i = add_neuron(g, "i", "input");
    m = add_neuron(g, "m", "identity");
    o = add_neuron(g, "o", "output");
    connect_neurons(i, m, 2.0);
    connect_neurons(m, o, 3.0);
    ids = collect_spliceable(g);
    assert ids == ["m"];
    res = splice_identity_neurons(g, True);
    assert res["removed"] == ["m"];
    assert edge_weight(i, o) == 6.0;
}

test "splice_disabled" {
    g = new_creature();
    res = splice_identity_neurons(g, False);
    assert res["removed"] == [];
    assert res["cascade"] == [];
}

test "prune_if_cascade" {
    g = new_creature();
    a = add_neuron(g, "a", "input");
    b = add_neuron(g, "b", "if", 0.5);
    c = add_neuron(g, "c", "output");
    connect_neurons(a, b, 1.0);
    connect_neurons(b, c, 2.0);
    r = prune_neuron(g, "b", True);
    assert r["ok"] == True;
    assert r["removed_neurons"] == ["b"];
    assert edge_weight(a, c) == 2.0;
}

test "prune_missing" {
    g = new_creature();
    r = prune_neuron(g, "ghost", True);
    assert r["ok"] == False;
    assert r["removed_neurons"] == [];
}
