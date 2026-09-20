"""stSoftwareAU/NEAT-AI-core#688 — recursive IDENTITY splice after prune/cleanup."""

node GraphRoot {
    has gid: str = "creature";
}

node Neuron {
    has nid: str;
    has kind: str;
    has bias: float = 0.0;
}

edge Synapse {
    has weight: float = 1.0;
}

obj PruneOutcome {
    has removed_neurons: list[str] = [];
    has synapse_count: int = 0;
}

walker CollectIdentity {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can root_entry with GraphRoot entry {
        print("collect_root", here.gid);
        kids: list[Neuron] = [];
        for ch in [here ++>][?:Neuron] {
            kids.append(ch);
        }
        visit :0: kids;
    }

    can collect with Neuron entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        print("collect", here.nid);
        if here.kind == "IDENTITY" {
            self.found.append(here.nid);
        }
        kids: list[Neuron] = [];
        for ch in [here ->:Synapse:->][?:Neuron] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker FindNeuron {
    has target: str;
    has claimed: dict[str, bool] = {};
    has found: Neuron | None = None;

    can root_seek with GraphRoot entry {
        print("seek_root", here.gid);
        kids: list[Neuron] = [];
        for ch in [here ++>][?:Neuron] {
            kids.append(ch);
        }
        visit kids;
    }

    can neuron_seek with Neuron entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        if here.nid == self.target {
            self.found = here;
            print("seek_hit", here.nid);
            disengage;
        }
        kids: list[Neuron] = [];
        for ch in [here ->:Synapse:->][?:Neuron] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker KindMap {
    has claimed: dict[str, bool] = {};
    has kinds: dict[str, str] = {};

    can root_kinds with GraphRoot entry {
        print("kinds_root", here.gid);
        kids: list[Neuron] = [];
        for ch in [here ++>][?:Neuron] {
            kids.append(ch);
        }
        visit kids;
    }

    can kind_step with Neuron entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        print("kind", here.nid);
        self.kinds[here.nid] = here.kind;
        kids: list[Neuron] = [];
        for ch in [here ->:Synapse:->][?:Neuron] {
            kids.append(ch);
        }
        visit :0: kids;
    }
}

def build_creature(
    neuron_specs: list[tuple[str, str, float]],
    synapse_specs: list[tuple[str, str, float]],
) -> GraphRoot {
    gr = GraphRoot();
    root ++> gr;
    registry: dict[str, Neuron] = {};
    for spec in neuron_specs {
        nid: str = spec[0];
        knd: str = spec[1];
        b: float = spec[2];
        nd = Neuron(nid=nid, kind=knd, bias=b);
        registry[nid] = nd;
        gr ++> nd;
    }
    for spec in synapse_specs {
        src_id: str = spec[0];
        dst_id: str = spec[1];
        wt: float = spec[2];
        src_n = registry[src_id];
        dst_n = registry[dst_id];
        src_n +>:Synapse(weight=wt):+> dst_n;
    }
    return gr;
}

def neuron_kinds(graph_root: GraphRoot) -> dict[str, str] {
    w = graph_root spawn KindMap(claimed={});
    return w.kinds;
}

def splice_identity_neuron(target: Neuron) -> int {
    added: int = 0;
    bias_delta: dict[str, float] = {};
    preds: list[Neuron] = [];
    for p in [target <-:Synapse:<-][?:Neuron] {
        preds.append(p);
    }
    succs: list[Neuron] = [];
    for s in [target ->:Synapse:->][?:Neuron] {
        succs.append(s);
    }
    for s in succs {
        out_w: float = 1.0;
        for e in [target ->:Synapse:-> s] {
            out_w = e.weight;
        }
        key: str = s.nid;
        cur: float = 0.0;
        if key in bias_delta {
            cur = bias_delta[key];
        }
        bias_delta[key] = cur + target.bias * out_w;
    }
    for p in preds {
        in_w: float = 1.0;
        for e in [p ->:Synapse:-> target] {
            in_w = e.weight;
            del e;
        }
        for s in succs {
            out_w: float = 1.0;
            for e in [target ->:Synapse:-> s] {
                out_w = e.weight;
            }
            new_w: float = in_w * out_w;
            merged: bool = False;
            for e in [p ->:Synapse:-> s] {
                e.weight = e.weight + new_w;
                merged = True;
            }
            if not merged {
                p +>:Synapse(weight=new_w):+> s;
                added = added + 1;
            }
        }
    }
    for s in succs {
        for e in [target ->:Synapse:-> s] {
            del e;
        }
        if s.nid in bias_delta {
            s.bias = s.bias + bias_delta[s.nid];
        }
    }
    return added;
}

def remove_neuron(neuron_id: str, victim: Neuron, outcome: PruneOutcome) -> None {
    outcome.removed_neurons.append(neuron_id);
    preds: list[Neuron] = [];
    for p in [victim <-:Synapse:<-][?:Neuron] {
        preds.append(p);
    }
    for p in preds {
        for e in [p ->:Synapse:-> victim] {
            del e;
        }
    }
    succs: list[Neuron] = [];
    for s in [victim ->:Synapse:->][?:Neuron] {
        succs.append(s);
    }
    for s in succs {
        for e in [victim ->:Synapse:-> s] {
            del e;
        }
    }
    del victim;
}

def cleanup_splice(graph_root: GraphRoot, splice_identity: bool) -> PruneOutcome {
    outcome = PruneOutcome();
    if not splice_identity {
        return outcome;
    }
    looping: bool = True;
    while looping {
        looping = False;
        collector = graph_root spawn CollectIdentity(claimed={});
        candidates: list[str] = [];
        for nid in collector.found {
            candidates.append(nid);
        }
        if len(candidates) == 0 {
            break;
        }
        sorted_cands: list[str] = sorted(candidates);
        pick: str = sorted_cands[0];
        picker = graph_root spawn FindNeuron(target=pick, claimed={});
        if picker.found is None {
            continue;
        }
        id_node = picker.found;
        if id_node.kind != "IDENTITY" {
            continue;
        }
        added = splice_identity_neuron(id_node);
        outcome.synapse_count = outcome.synapse_count + added;
        remove_neuron(id_node.nid, id_node, outcome);
        looping = True;
    }
    return outcome;
}

"""stSoftwareAU/NEAT-AI-core#688 — guard tests."""

import from .iss_stSoftwareAU__NEAT-AI-core__688 {
    build_creature,
    neuron_kinds,
    splice_identity_neuron,
    cleanup_splice,
    FindNeuron,
}

test "build_creature_kinds" {
    gr = build_creature(
        [("in0", "INPUT", 0.0), ("h0", "HIDDEN", 0.2)],
        [("in0", "h0", 1.0)],
    );
    kinds = neuron_kinds(gr);
    assert (kinds["in0"] == "INPUT");;
    assert (kinds["h0"] == "HIDDEN");;
}

test "splice_single_identity" {
    gr = build_creature(
        [("a", "HIDDEN", 0.0), ("id", "IDENTITY", 0.5), ("b", "HIDDEN", 0.0)],
        [("a", "id", 2.0), ("id", "b", 3.0)],
    );
    seeker = gr spawn FindNeuron(target="id", claimed={});
    assert (seeker.found is not None);;
    added = splice_identity_neuron(seeker.found);
    assert (added == 1);;
    kinds = neuron_kinds(gr);
    assert (kinds["id"] == "IDENTITY");;
}

test "cleanup_disabled_noop" {
    gr = build_creature(
        [("a", "HIDDEN", 0.0), ("id", "IDENTITY", 0.0), ("b", "HIDDEN", 0.0)],
        [("a", "id", 1.0), ("id", "b", 1.0)],
    );
    outcome = cleanup_splice(gr, False);
    assert (len(outcome.removed_neurons) == 0);;
    assert (outcome.synapse_count == 0);;
}

test "cleanup_recursive_identities" {
    gr = build_creature(
        [
            ("src", "HIDDEN", 0.0),
            ("id1", "IDENTITY", 0.1),
            ("id2", "IDENTITY", 0.2),
            ("dst", "HIDDEN", 0.0),
        ],
        [
            ("src", "id1", 1.0),
            ("id1", "id2", 1.0),
            ("id2", "dst", 1.0),
        ],
    );
    outcome = cleanup_splice(gr, True);
    assert (outcome.removed_neurons == ["id1", "id2"]);;
    assert (outcome.synapse_count == 1);;
    kinds = neuron_kinds(gr);
    has_identity: bool = False;
    for nid in kinds {
        if kinds[nid] == "IDENTITY" {
            has_identity = True;
        }
    }
    assert (not has_identity);;
}

test "cleanup_sorted_pick_order" {
    gr = build_creature(
        [
            ("src", "HIDDEN", 0.0),
            ("z_id", "IDENTITY", 0.0),
            ("a_id", "IDENTITY", 0.0),
            ("dst", "HIDDEN", 0.0),
        ],
        [
            ("src", "z_id", 1.0),
            ("src", "a_id", 1.0),
            ("z_id", "dst", 1.0),
            ("a_id", "dst", 1.0),
        ],
    );
    outcome = cleanup_splice(gr, True);
    assert (outcome.removed_neurons[0] == "a_id");;
    assert (len(outcome.removed_neurons) == 2);;
}
