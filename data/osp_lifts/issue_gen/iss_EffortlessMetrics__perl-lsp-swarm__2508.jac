"""EffortlessMetrics/perl-lsp-swarm#2508 — incremental per-file semantic facts."""

node Scope {
    has sid: str;
    has fact: str | None = None;
    has anchor: int | None = None;
}

edge ChildOf {}
edge DependsOn {}

obj SemanticGraph {
    has scopes: dict[str, Scope] = {};
}

walker EnclosingChainWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with Scope entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.chain.append(here.sid);
        parents = [here ->:ChildOf:->][?:Scope];
        names: list[str] = [];
        for p in parents { names.append(p.sid); }
        for nm in sorted(names) {
            for p in parents {
                if p.sid == nm { visit [p]; }
            }
        }
    }
}

walker DependentContribWalk {
    has claimed: dict[str, bool] = {};
    has seeds: dict[str, bool] = {};

    can step with Scope entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        consumers = [here <-:DependsOn:<-][?:Scope];
        names: list[str] = [];
        for c in consumers { names.append(c.sid); }
        for nm in sorted(names) {
            for c in consumers {
                if c.sid == nm {
                    nested = False;
                    pars = [c ->:ChildOf:->][?:Scope];
                    for p in pars {
                        if p.sid == here.sid { nested = True; }
                    }
                    if not nested or here.sid in self.seeds {
                        visit [c];
                    }
                }
            }
        }
    }
}

def _snapshot_facts(g: SemanticGraph) -> dict[str, str] {
    facts: dict[str, str] = {};
    keys: list[str] = [];
    for sid in g.scopes { keys.append(sid); }
    for sid in sorted(keys) {
        nd = g.scopes[sid];
        if nd.fact is not None { facts[sid] = nd.fact; }
    }
    return facts;
}

def _snapshot_anchors(g: SemanticGraph) -> dict[str, int] {
    anchors: dict[str, int] = {};
    keys: list[str] = [];
    for sid in g.scopes { keys.append(sid); }
    for sid in sorted(keys) {
        nd = g.scopes[sid];
        if nd.anchor is not None { anchors[sid] = nd.anchor; }
    }
    return anchors;
}

def load_semantic_graph(
    scopes: list[str],
    parent_of: list[tuple[str, str | None]],
    depends: list[tuple[str, str]],
    facts: dict[str, str],
    anchors: dict[str, int],
) -> SemanticGraph {
    g = SemanticGraph();
    for sid in scopes {
        nd = Scope(sid=sid);
        root ++> nd;
        g.scopes[sid] = nd;
    }
    for (child, parent) in parent_of {
        if child in g.scopes {
            if parent is not None and parent in g.scopes {
                ch = g.scopes[child];
                par = g.scopes[parent];
                ch +>:ChildOf:+> par;
            }
        }
    }
    for (consumer, producer) in depends {
        if consumer in g.scopes and producer in g.scopes {
            con = g.scopes[consumer];
            pro = g.scopes[producer];
            con +>:DependsOn:+> pro;
        }
    }
    for (sid, val) in facts.items() {
        if sid in g.scopes { g.scopes[sid].fact = val; }
    }
    for (sid, pos) in anchors.items() {
        if sid in g.scopes { g.scopes[sid].anchor = pos; }
    }
    return g;
}

def enclosing_scope_chain(g: SemanticGraph, scope: str) -> list[str] {
    if scope not in g.scopes { return []; }
    nd = g.scopes[scope];
    w = nd spawn EnclosingChainWalk(claimed={}, chain=[]);
    return w.chain;
}

def dependent_contributions(g: SemanticGraph, seeds: list[str]) -> list[str] {
    claimed: dict[str, bool] = {};
    seed_map: dict[str, bool] = {};
    seed_keys: list[str] = [];
    for s in seeds {
        if s in g.scopes {
            seed_keys.append(s);
            seed_map[s] = True;
        }
    }
    for s in sorted(seed_keys) {
        nd = g.scopes[s];
        w = nd spawn DependentContribWalk(claimed=claimed, seeds=seed_map);
        claimed = w.claimed;
        seed_map = w.seeds;
    }
    out: list[str] = [];
    for k in claimed { out.append(k); }
    return sorted(out);
}

def refresh_facts(
    g: SemanticGraph,
    seeds: list[str],
    impact: str,
    shift: int = 0,
    recomputed: dict[str, str] | None = None,
) -> tuple[str, dict[str, str], dict[str, int]] {
    facts = _snapshot_facts(g);
    anchors = _snapshot_anchors(g);
    if impact == "no_change" {
        return ("retain", facts, anchors);
    }
    if impact == "topology" {
        payload: dict[str, str] = {};
        if recomputed is not None {
            for (k, v) in recomputed.items() { payload[k] = v; }
        }
        return ("fallback", payload, anchors);
    }
    if impact == "range_shift" {
        for sid in seeds {
            if sid in anchors { anchors[sid] = anchors[sid] + shift; }
        }
        return ("rebase", facts, anchors);
    }
    affected: dict[str, bool] = {};
    touched = dependent_contributions(g, seeds);
    for sid in touched { affected[sid] = True; }
    kept: dict[str, str] = {};
    payload: dict[str, str] = {};
    if recomputed is not None {
        for (k, v) in recomputed.items() { payload[k] = v; }
    }
    for (sid, val) in facts.items() {
        if sid not in affected { kept[sid] = val; }
    }
    aff_keys: list[str] = [];
    for sid in affected { aff_keys.append(sid); }
    for sid in sorted(aff_keys) {
        if sid in payload {
            kept[sid] = payload[sid];
        } elif sid in facts {
            kept[sid] = facts[sid];
        }
    }
    return ("recompute", kept, anchors);
}
