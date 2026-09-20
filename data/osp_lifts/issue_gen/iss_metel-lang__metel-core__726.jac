"""metel-lang/metel-core#726 — RFC-0128 comptime settlement probe.
Recursion depth, allocation shapes, and sized-array impl verification.
"""

node Query {
    has qid: str;
    has topic: str;
    has alloc_shape: str = "fixed";
    has array_arity: int = 0;
    has settled: bool = False;
}

edge Blocks {}

node TypeTarget {
    has tid: str;
    has arity: int = 0;
    has copy_ok: bool = False;
}

edge Requires {}

def find_query(handle: object, qid: str) -> Query | None {
    qs = handle["queries"] as list[Query];
    for q in qs {
        if q.qid == qid {
            return q;
        }
    }
    return None;
}

def build_settlement_graph -> object {
    store: dict[str, object] = {};
    graph_root = Query(qid="rfc0128", topic="comptime_model", settled=False);
    oq1 = Query(qid="oq1", topic="recursion", settled=False);
    oq1b = Query(qid="oq1b", topic="recursion", settled=False);
    oq1c = Query(qid="oq1c", topic="recursion", settled=False);
    oq2_fixed = Query(qid="oq2_fixed", topic="allocation", alloc_shape="fixed", settled=False);
    oq2_grow = Query(qid="oq2_grow", topic="allocation", alloc_shape="growable", settled=False);
    oq5 = Query(qid="oq5", topic="sized_array", array_arity=2, settled=False);
    tgt = TypeTarget(tid="pair_copy", arity=2, copy_ok=True);
    graph_root ++> oq1;
    oq1 ++> oq1b;
    oq1b ++> oq1c;
    graph_root ++> oq2_fixed;
    oq2_fixed +>:Blocks:+> oq2_grow;
    oq2_grow +>:Blocks:+> oq2_fixed;
    graph_root ++> oq5;
    oq5 +>:Requires:+> tgt;
    store["root"] = graph_root;
    store["queries"] = [graph_root, oq1, oq1b, oq1c, oq2_fixed, oq2_grow, oq5];
    store["targets"] = [tgt];
    return store;
}

def query_by_id(handle: object, qid: str) -> dict | None {
    q = find_query(handle, qid);
    if q is None {
        return None;
    }
    out: dict = {};
    out["qid"] = q.qid;
    out["topic"] = q.topic;
    out["alloc_shape"] = q.alloc_shape;
    out["array_arity"] = q.array_arity;
    out["settled"] = q.settled;
    return out;
}

def comptime_closure_depth(handle: object, root_qid: str, max_depth: int) -> dict {
    start = find_query(handle, root_qid);
    empty: dict = {};
    empty["order"] = [];
    empty["hit_limit"] = False;
    empty["max_seen_depth"] = 0;
    if start is None {
        return empty;
    }
    w = start spawn RecursionWalker(
        claimed={},
        max_depth=max_depth,
        depth=0,
        order=[],
        hit_limit=False,
        max_seen_depth=0,
    );
    out: dict = {};
    out["order"] = w.order;
    out["hit_limit"] = w.hit_limit;
    out["max_seen_depth"] = w.max_seen_depth;
    return out;
}

def allocation_shapes_in_closure(handle: object, root_qid: str) -> list[str] {
    start = find_query(handle, root_qid);
    if start is None {
        return [];
    }
    w = start spawn AllocationWalker(claimed={}, shapes=[]);
    return sorted(w.shapes);
}

def verify_sized_array_impl(handle: object, type_id: str, expected_arity: int) -> bool {
    targets = handle["targets"] as list[TypeTarget];
    for t in targets {
        if t.tid == type_id and t.arity == expected_arity and t.copy_ok {
            return True;
        }
    }
    qs = handle["queries"] as list[Query];
    for q in qs {
        if q.qid != "oq5" {
            continue;
        }
        for ch in [q ->:Requires:->][?:TypeTarget] {
            if ch.tid == type_id and ch.arity == expected_arity and ch.copy_ok {
                return True;
            }
        }
    }
    return False;
}

walker RecursionWalker {
    has claimed: dict[str, bool] = {};
    has max_depth: int = 64;
    has depth: int = 0;
    has order: list[str] = [];
    has hit_limit: bool = False;
    has max_seen_depth: int = 0;

    can walk_query with Query entry {
        if here.qid in self.claimed {
            skip;
        }
        self.claimed[here.qid] = True;
        self.order.append(here.qid);
        if self.depth > self.max_seen_depth {
            self.max_seen_depth = self.depth;
        }
        if self.depth >= self.max_depth {
            self.hit_limit = True;
            print {"event": "depth_limit", "at": here.qid, "depth": self.depth};
            disengage;
        }
        kids: list[Query] = [];
        for ch in [here ->] {
            kids.append(ch);
        }
        for ch in [here ->:Blocks:->][?:Query] {
            kids.append(ch);
        }
        if kids {
            self.depth += 1;
            visit :0: kids;
            self.depth -= 1;
        } else {
            disengage;
        }
        print {"recursion_probe": here.qid, "depth": self.depth};
    }
}

walker AllocationWalker {
    has claimed: dict[str, bool] = {};
    has shapes: list[str] = [];

    can collect_query with Query entry {
        if here.qid in self.claimed {
            skip;
        }
        self.claimed[here.qid] = True;
        s = here.alloc_shape;
        seen = False;
        for x in self.shapes {
            if x == s {
                seen = True;
            }
        }
        if not seen {
            self.shapes.append(s);
        }
        kids: list[Query] = [];
        for ch in [here ->] {
            kids.append(ch);
        }
        for ch in [here ->:Blocks:->][?:Query] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
        print {"alloc_probe": here.qid, "shape": here.alloc_shape};
    }
}
