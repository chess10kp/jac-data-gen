"""Span tree queries with pruned ancestor/descent walks.

pydantic/pydantic-ai#7484 lifted to OSP: SpanNode becomes a node
archetype; the parent back-reference and children list collapse into one
typed ChildSpan edge family walked upward for ancestors and downward for
descendants. Query evaluation spawns a fresh pruned walk per side, so
every ancestor/descendant condition sees the full pruned closure -- the
cached-generator exhaustion defect cannot recur structurally. Prune
conditions are explicit domain policy inside the walkers.
"""
node SpanNode {
    has name: str;
    has span_id: int;
    has attrs: dict[str, str] = {};
}

edge ChildSpan {}

"""Constructor equivalent + root attachment."""
def make_span(name: str, span_id: int, attrs: dict[str, str] = {}) -> SpanNode {
    s = SpanNode(name=name, span_id=span_id, attrs=attrs);
    root ++> s;
    return s;
}

def add_child(parent: SpanNode, child: SpanNode) -> SpanNode {
    parent +>:ChildSpan:+> child;
    return child;
}

# Single condition check against a node's attrs; all pairs must hold.
def cond_holds(n: SpanNode, cond: dict) -> bool {
    for k in cond.keys() {
        if n.attrs.get(k) != cond[k] {
            return False;
        }
    }
    return True;
}

# Linear ascent over ChildSpan; nearest-first order is the walk order.
walker AncWalk {
    has stop: dict | None = None;
    has out: list[SpanNode] = [];
    has first: bool = True;

    can step with SpanNode entry {
        if self.first {
            self.first = False;
        } else {
            if self.stop is not None {
                if cond_holds(here, self.stop) {
                    skip;
                }
            }
            self.out.append(here);
        }
        visit [<-:ChildSpan:<-];
    }
}

# Down-walk; prune policy: a stop-matching node is excluded and not
# descended past. Shared child nodes are revisited (multiset semantics).
walker DescWalk {
    has stop: dict | None = None;
    has out: list[SpanNode] = [];
    has first: bool = True;

    can step with SpanNode entry {
        if self.first {
            self.first = False;
        } else {
            if self.stop is not None {
                if cond_holds(here, self.stop) {
                    skip;
                }
            }
            self.out.append(here);
        }
        visit [->:ChildSpan:->];
    }
}

def ancestors(n: SpanNode) -> list[SpanNode] {
    w = n spawn AncWalk();
    return w.out;
}

def descendants(n: SpanNode) -> list[SpanNode] {
    w = n spawn DescWalk();
    return w.out;
}

def _pruned_ancestors(n: SpanNode, stop: dict | None) -> list[SpanNode] {
    w = n spawn AncWalk(stop=stop);
    return w.out;
}

def _pruned_descendants(n: SpanNode, stop: dict | None) -> list[SpanNode] {
    w = n spawn DescWalk(stop=stop);
    return w.out;
}

def matches(n: SpanNode, query: dict) -> bool {
    stop: dict | None = query.get("stop_recursing_when");
    anc = _pruned_ancestors(n, stop);
    desc = _pruned_descendants(n, stop);
    anc_all: list[dict] = query.get("all_ancestors_have", []);
    for cond in anc_all {
        for a in anc {
            if not cond_holds(a, cond) {
                return False;
            }
        }
    }
    anc_none: list[dict] = query.get("no_ancestor_has", []);
    for cond in anc_none {
        for a in anc {
            if cond_holds(a, cond) {
                return False;
            }
        }
    }
    anc_some: list[dict] = query.get("some_ancestor_has", []);
    for cond in anc_some {
        found = False;
        for a in anc {
            if cond_holds(a, cond) {
                found = True;
            }
        }
        if not found {
            return False;
        }
    }
    desc_all: list[dict] = query.get("all_descendants_have", []);
    for cond in desc_all {
        for d in desc {
            if not cond_holds(d, cond) {
                return False;
            }
        }
    }
    desc_none: list[dict] = query.get("no_descendant_has", []);
    for cond in desc_none {
        for d in desc {
            if cond_holds(d, cond) {
                return False;
            }
        }
    }
    desc_some: list[dict] = query.get("some_descendant_has", []);
    for cond in desc_some {
        found = False;
        for d in desc {
            if cond_holds(d, cond) {
                found = True;
            }
        }
        if not found {
            return False;
        }
    }
    return True;
}


test "ancestors nearest-first over parent edges" {
    root_n = make_span("root", 1, {"name": "root"});
    mid = make_span("mid", 2, {"name": "mid"});
    gate = make_span("gate", 3, {"name": "gate"});
    leaf = make_span("leaf", 4, {"name": "leaf"});
    add_child(root_n, mid);
    add_child(mid, gate);
    add_child(gate, leaf);
    anc: list[str] = [];
    for a in ancestors(leaf) {
        anc.append(a.name);
    }
    assert anc == ["gate", "mid", "root"];
    assert len(ancestors(root_n)) == 0;
}

test "descendants multiset with shared diamond node" {
    dr = make_span("dr", 20, {"name": "dr"});
    l = make_span("l", 21, {"name": "l"});
    r = make_span("r", 22, {"name": "r"});
    shared = make_span("shared", 23, {"name": "shared"});
    add_child(dr, l);
    add_child(dr, r);
    add_child(l, shared);
    add_child(r, shared);
    names: list[str] = [];
    for d in descendants(dr) {
        names.append(d.name);
    }
    assert names.count("shared") == 2;
    assert sorted(names) == ["l", "r", "shared", "shared"];
    assert matches(dr, {"some_descendants_have": [{"name": "shared"}]});
    assert not matches(dr, {"all_descendants_have": [{"name": "shared"}]});
}

test "multiple conditions each see the full pruned walk" {
    root_n = make_span("q_root", 1, {"name": "q_root"});
    mid = make_span("q_mid", 2, {"name": "q_mid"});
    gate = make_span("q_gate", 3, {"name": "q_gate"});
    leaf = make_span("q_leaf", 4, {"name": "q_leaf"});
    add_child(root_n, mid);
    add_child(mid, gate);
    add_child(gate, leaf);
    plain = {"all_ancestors_have": [{"name": "q_mid"}], "no_ancestor_has": [{"name": "q_root"}]};
    assert not matches(leaf, plain);
    inert = {"all_ancestors_have": [{"name": "q_mid"}], "no_ancestor_has": [{"name": "q_root"}], "stop_recursing_when": {"name": "never-matches"}};
    assert not matches(leaf, inert);
}

test "prune truncates the walk at matching nodes" {
    root_n = make_span("p_root", 1, {"name": "p_root"});
    mid = make_span("p_mid", 2, {"name": "p_mid"});
    gate = make_span("p_gate", 3, {"name": "p_gate"});
    leaf = make_span("p_leaf", 4, {"name": "p_leaf"});
    add_child(root_n, mid);
    add_child(mid, gate);
    add_child(gate, leaf);
    assert matches(leaf, {"no_ancestor_has": [{"name": "p_root"}], "stop_recursing_when": {"name": "p_gate"}});
    assert not matches(leaf, {"some_ancestor_has": [{"name": "p_mid"}], "stop_recursing_when": {"name": "p_gate"}});
}

test "descendant error detection and subtree prune" {
    job = make_span("job", 10, {"name": "job"});
    ok_step = make_span("ok1", 11, {"name": "ok1"});
    err = make_span("err", 12, {"name": "err", "status": "error"});
    inner = make_span("inner", 13, {"name": "inner"});
    add_child(job, ok_step);
    add_child(job, err);
    add_child(err, inner);
    assert not matches(job, {"no_descendant_has": [{"status": "error"}]});
    assert matches(job, {"some_descendant_has": [{"status": "error"}]});
    assert not matches(job, {"all_descendants_have": [{"status": "error"}]});
    assert not matches(job, {"all_descendants_have": [{"name": "x"}], "no_descendant_has": [{"status": "error"}]});
    assert matches(job, {"no_descendant_has": [{"status": "error"}], "stop_recursing_when": {"status": "error"}});
    assert matches(job, {});
    assert not matches(job, {"some_ancestor_has": [{"status": "error"}]});
}
