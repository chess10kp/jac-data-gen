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

test "dependent contributions diamond revisit merge" {
    g = load_semantic_graph(
        ["s", "left", "right", "join"],
        [],
        [("left", "s"), ("right", "s"), ("join", "left"), ("join", "right")],
        {},
        {},
    );
    assert dependent_contributions(g, ["s"]) == ["join", "left", "right", "s"];;
    assert dependent_contributions(g, ["join"]) == ["join"];;
}

test "dependent contributions skips nested off non seed hops" {
    g = load_semantic_graph(
        ["pkg", "sub_a", "sub_b", "tok_hover", "tok_def"],
        [
            ("pkg", None),
            ("sub_a", "pkg"),
            ("sub_b", "pkg"),
            ("tok_hover", "sub_a"),
            ("tok_def", "sub_b"),
        ],
        [("tok_hover", "sub_a"), ("tok_def", "sub_b"), ("sub_b", "sub_a")],
        {},
        {},
    );
    assert dependent_contributions(g, ["sub_a"]) == ["sub_a", "sub_b", "tok_hover"];;
    assert dependent_contributions(g, ["sub_b"]) == ["sub_b", "tok_def"];;
    assert dependent_contributions(g, ["ghost"]) == [];;
}

test "enclosing scope parent cycle claim skip" {
    g = load_semantic_graph(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
        [],
        {},
        {},
    );
    assert enclosing_scope_chain(g, "a") == ["a", "b", "c"];;
    assert enclosing_scope_chain(g, "ghost") == [];;
}

test "unknown id tolerance across api" {
    g = load_semantic_graph(
        ["only"],
        [("only", "ghost")],
        [("only", "ghost"), ("ghost", "only")],
        {"only": "ok", "ghost": "drop"},
        {"only": 7, "ghost": 99},
    );
    assert enclosing_scope_chain(g, "missing") == [];;
    assert dependent_contributions(g, ["missing", "only"]) == ["only"];;
    (mode, facts, anchors) = refresh_facts(
        g,
        ["missing", "only"],
        "range_shift",
        shift=3,
    );
    assert mode == "rebase";;
    assert facts == {"only": "ok"};;
    assert anchors == {"only": 10};;
}

test "load drops ghost scope references" {
    g = load_semantic_graph(
        ["x"],
        [("x", "ghost")],
        [("ghost", "x"), ("x", "ghost")],
        {"ghost": "f", "x": "g"},
        {"ghost": 1, "x": 2},
    );
    assert enclosing_scope_chain(g, "x") == ["x"];;
    assert dependent_contributions(g, ["x"]) == ["x"];;
    facts: dict[str, str] = {};
    anchors: dict[str, int] = {};
    for sid in g.scopes {
        nd = g.scopes[sid];
        if nd.fact is not None { facts[sid] = nd.fact; }
        if nd.anchor is not None { anchors[sid] = nd.anchor; }
    }
    assert facts == {"x": "g"};;
    assert anchors == {"x": 2};;
}

test "refresh facts recompute preserves outside affected" {
    g = load_semantic_graph(
        ["s", "a", "b", "z"],
        [],
        [("a", "s")],
        {"s": "1", "a": "2", "b": "3", "z": "4"},
        {"s": 10, "b": 20},
    );
    (mode, kept, anchors) = refresh_facts(
        g,
        ["s"],
        "content",
        recomputed={"a": "NEW"},
    );
    assert mode == "recompute";;
    assert kept == {"a": "NEW", "b": "3", "s": "1", "z": "4"};;
    assert anchors == {"b": 20, "s": 10};;
}

test "refresh facts body change omits sibling nested tokens" {
    g = load_semantic_graph(
        ["pkg", "sub_a", "sub_b", "tok_hover", "tok_def"],
        [
            ("pkg", None),
            ("sub_a", "pkg"),
            ("sub_b", "pkg"),
            ("tok_hover", "sub_a"),
            ("tok_def", "sub_b"),
        ],
        [("tok_hover", "sub_a"), ("tok_def", "sub_b"), ("sub_b", "sub_a")],
        {
            "pkg": "package:Main",
            "sub_a": "sub:name",
            "sub_b": "sub:other",
            "tok_hover": "hover:text",
            "tok_def": "def:other",
        },
        {"pkg": 0, "sub_a": 10, "sub_b": 40, "tok_hover": 12, "tok_def": 42},
    );
    (mode, facts, anchors) = refresh_facts(
        g,
        ["sub_a"],
        "body_change",
        recomputed={
            "sub_a": "sub:renamed",
            "sub_b": "sub:updated",
            "tok_hover": "hover:new",
        },
    );
    assert mode == "recompute";;
    assert facts == {
        "pkg": "package:Main",
        "sub_a": "sub:renamed",
        "sub_b": "sub:updated",
        "tok_hover": "hover:new",
        "tok_def": "def:other",
    };;
    assert anchors == {
        "pkg": 0,
        "sub_a": 10,
        "sub_b": 40,
        "tok_hover": 12,
        "tok_def": 42,
    };;
}

test "refresh facts topology fallback empty payload" {
    g = load_semantic_graph(
        ["p"],
        [],
        [],
        {"p": "v"},
        {"p": 5},
    );
    (mode, facts, anchors) = refresh_facts(g, ["p"], "topology");
    assert mode == "fallback";;
    assert facts == {};;
    assert anchors == {"p": 5};;
}
