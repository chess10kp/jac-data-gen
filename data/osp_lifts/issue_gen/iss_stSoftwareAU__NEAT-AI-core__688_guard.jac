"""Prune cleanup: recursive IDENTITY neuron splice — stSoftwareAU/NEAT-AI-core#688."""

node Neuron {
    has nid: str;
    has kind: str;
    has bias: float = 0.0;
    has alive: bool = True;
}

edge Synapse {
    has weight: float = 1.0;
}

walker IndexW {
    has claimed: dict[str, bool] = {};
    has store: dict[str, Neuron] = {};

    can step with Neuron entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        self.store[here.nid] = here;
        print("index", here.nid);
        kids: list[Neuron] = [];
        for ch in [here ->:Synapse:->][?:Neuron] {
            if ch.alive {
                kids.append(ch);
            }
        }
        visit :0: kids else {
            disengage;
        }
    }
}

walker CollectIdentityW {
    has claimed: dict[str, bool] = {};
    has found: list[str] = {};

    can step with Neuron entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        if here.alive && here.kind == "IDENTITY" {
            self.found.append(here.nid);
        }
        print("collect", here.nid, here.kind);
        kids: list[Neuron] = [];
        for ch in [here ->:Synapse:->][?:Neuron] {
            if ch.alive {
                kids.append(ch);
            }
        }
        visit :0: kids else {
            disengage;
        }
    }
}

def make_neuron(nid: str, kind: str, bias: float) -> Neuron {
    return Neuron(nid=nid, kind=kind, bias=bias);
}

def wire(src: Neuron, tgt: Neuron, w: float) -> None {
    src +>:Synapse(weight=w):+> tgt;
}

def index_nodes(graph_root: Neuron) -> dict[str, Neuron] {
    store: dict[str, Neuron] = {};
    w = graph_root spawn IndexW(claimed={}, store=store);
    print("indexed", len(w.store));
    return w.store;
}

def merge_edge(src: Neuron, tgt: Neuron, w: float) -> None {
    for syn in [src ->:Synapse:] {
        tgts: list[Neuron] = [syn ->:Synapse:->][?:Neuron];
        for t in tgts {
            if t == tgt {
                syn.weight = syn.weight + w;
                return;
            }
        }
    }
    src +>:Synapse(weight=w):+> tgt;
}

def purge_synapses(n: Neuron) -> None {
    doomed: list[Synapse] = [];
    for syn in [n ->:Synapse:] {
        doomed.append(syn);
    }
    for syn in [n <-:Synapse:] {
        doomed.append(syn);
    }
    for syn in doomed {
        destroy syn;
    }
}

def splice_one(n: Neuron) -> bool {
    if !n.alive || n.kind != "IDENTITY" {
        return False;
    }
    has_in: bool = False;
    has_out: bool = False;
    for syn in [n <-:Synapse:] {
        srcs: list[Neuron] = [syn <-:Synapse:<-][?:Neuron];
        for src in srcs {
            if src.alive {
                has_in = True;
            }
        }
    }
    for syn in [n ->:Synapse:] {
        tgts: list[Neuron] = [syn ->:Synapse:->][?:Neuron];
        for tgt in tgts {
            if tgt.alive {
                has_out = True;
            }
        }
    }
    if !has_in && !has_out {
        n.alive = False;
        return True;
    }
    if !has_in || !has_out {
        return False;
    }
    for syn_out in [n ->:Synapse:] {
        tgts: list[Neuron] = [syn_out ->:Synapse:->][?:Neuron];
        for tgt in tgts {
            if tgt.alive {
                tgt.bias = tgt.bias + (syn_out.weight * n.bias);
            }
        }
    }
    for syn_in in [n <-:Synapse:] {
        srcs: list[Neuron] = [syn_in <-:Synapse:<-][?:Neuron];
        for src in srcs {
            if !src.alive {
                continue;
            }
            w_in = syn_in.weight;
            for syn_out in [n ->:Synapse:] {
                tgts: list[Neuron] = [syn_out ->:Synapse:->][?:Neuron];
                for tgt in tgts {
                    if tgt.alive {
                        merge_edge(src, tgt, w_in * syn_out.weight);
                    }
                }
            }
        }
    }
    purge_synapses(n);
    n.alive = False;
    return True;
}

def neuron_kind(graph_root: Neuron, nid: str) -> str {
    store = index_nodes(graph_root);
    if nid in store {
        n = store[nid];
        if n.alive {
            return n.kind;
        }
    }
    return "UNKNOWN";
}

def synapse_weight(graph_root: Neuron, src_id: str, tgt_id: str) -> float {
    store = index_nodes(graph_root);
    if src_id not in store || tgt_id not in store {
        return -1.0;
    }
    src = store[src_id];
    tgt = store[tgt_id];
    if !src.alive || !tgt.alive {
        return -1.0;
    }
    for syn in [src ->:Synapse:] {
        tgts: list[Neuron] = [syn ->:Synapse:->][?:Neuron];
        for t in tgts {
            if t == tgt {
                return syn.weight;
            }
        }
    }
    return -1.0;
}

def cleanup_identity_splice(graph_root: Neuron) -> dict {
    removed: list[str] = [];
    loop_again: bool = True;
    while loop_again {
        loop_again = False;
        w = graph_root spawn CollectIdentityW(claimed={}, found=[]);
        ids: list[str] = [];
        for nid in w.found {
            ids.append(nid);
        }
        ids.sort();
        for nid in ids {
            store = index_nodes(graph_root);
            if nid not in store {
                continue;
            }
            n = store[nid];
            if splice_one(n) {
                removed.append(nid);
                loop_again = True;
                print("spliced", nid);
            }
        }
    }
    return {"removed_neurons": removed, "cascade_neurons": removed};
}

def build_simple_identity -> Neuron {
    a = make_neuron("a", "INPUT", 0.0);
    id1 = make_neuron("id1", "IDENTITY", 2.0);
    b = make_neuron("b", "OUTPUT", 0.0);
    graph_root = make_neuron("__root__", "ROOT", 0.0);
    graph_root ++> a;
    graph_root ++> id1;
    graph_root ++> b;
    wire(a, id1, 0.5);
    wire(id1, b, 3.0);
    return graph_root;
}

def build_cascade_identity -> Neuron {
    a = make_neuron("a", "INPUT", 0.0);
    id1 = make_neuron("id1", "IDENTITY", 1.0);
    id2 = make_neuron("id2", "IDENTITY", 2.0);
    b = make_neuron("b", "OUTPUT", 0.0);
    graph_root = make_neuron("__root__", "ROOT", 0.0);
    graph_root ++> a;
    graph_root ++> id1;
    graph_root ++> id2;
    graph_root ++> b;
    wire(a, id1, 1.0);
    wire(id1, id2, 1.0);
    wire(id2, b, 1.0);
    return graph_root;
}

def build_diamond_identity -> Neuron {
    i1 = make_neuron("i1", "INPUT", 0.0);
    i2 = make_neuron("i2", "INPUT", 0.0);
    id1 = make_neuron("id1", "IDENTITY", 0.0);
    out = make_neuron("out", "OUTPUT", 0.0);
    graph_root = make_neuron("__root__", "ROOT", 0.0);
    graph_root ++> i1;
    graph_root ++> i2;
    graph_root ++> id1;
    graph_root ++> out;
    wire(i1, id1, 2.0);
    wire(i2, id1, 3.0);
    wire(id1, out, 1.0);
    return graph_root;
}

def build_if_passthrough -> Neuron {
    a = make_neuron("a", "INPUT", 0.0);
    mid = make_neuron("mid", "IF", 0.0);
    b = make_neuron("b", "OUTPUT", 0.0);
    graph_root = make_neuron("__root__", "ROOT", 0.0);
    graph_root ++> a;
    graph_root ++> mid;
    graph_root ++> b;
    wire(a, mid, 1.0);
    wire(mid, b, 1.0);
    return graph_root;
}

test "simple_identity_splice" {
    g = build_simple_identity();
    res = cleanup_identity_splice(g);
    assert (res["removed_neurons"] == ["id1"]);;
    assert (neuron_kind(g, "id1") == "UNKNOWN");;
    assert (synapse_weight(g, "a", "b") == 1.5);;
}

test "cascade_identity_splice" {
    g = build_cascade_identity();
    res = cleanup_identity_splice(g);
    assert (res["removed_neurons"] == ["id1", "id2"]);;
    assert (synapse_weight(g, "a", "b") == 1.0);;
    assert (neuron_kind(g, "b") == "OUTPUT");;
}

test "diamond_identity_splice" {
    g = build_diamond_identity();
    res = cleanup_identity_splice(g);
    assert (res["removed_neurons"] == ["id1"]);;
    assert (synapse_weight(g, "i1", "out") == 2.0);;
    assert (synapse_weight(g, "i2", "out") == 3.0);;
}

test "if_not_spliced" {
    g = build_if_passthrough();
    res = cleanup_identity_splice(g);
    assert (res["removed_neurons"] == []);;
    assert (neuron_kind(g, "mid") == "IF");;
    assert (synapse_weight(g, "a", "b") == -1.0);;
}

test "unknown_neuron_kind" {
    g = build_simple_identity();
    cleanup_identity_splice(g);
    assert (neuron_kind(g, "missing") == "UNKNOWN");;
}
