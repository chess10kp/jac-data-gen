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
