"""EffortlessMetrics/perl-lsp-swarm#9783 — Mojo::Promise continuation tuple propagation."""

node Continuation {
    has fid: str;
    has fact: dict;
}

edge ContinuesTo {}

walker ReachWalker {
    has adj: dict[str, list[str]] = {};
    has nodes: dict[str, Continuation] = {};
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Continuation entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        self.order.append(here.fid);
        for kid in self.adj.get(here.fid, []) {
            kn = self.nodes.get(kid, None);
            if kn is not None { visit [kn]; }
        }
    }
}

walker PathBranch {
    has adj: dict[str, list[str]] = {};
    has nodes: dict[str, Continuation] = {};
    has trail: list[str] = [];
    has paths: list[list[str]] = [];

    can step with Continuation entry {
        if here.fid in self.trail {
            snap: list[str] = [];
            for x in self.trail { snap.append(x); }
            snap.append(here.fid);
            self.paths.append(snap);
            skip;
        }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.fid);
        kids = self.adj.get(here.fid, []);
        if not kids {
            self.paths.append(nt);
            skip;
        }
        for kid in kids {
            kn = self.nodes.get(kid, None);
            if kn is not None {
                kn spawn PathBranch(
                    adj=self.adj,
                    nodes=self.nodes,
                    trail=nt,
                    paths=self.paths,
                );
            }
        }
    }
}

def _ensure_continuation_node(
    nodes: dict[str, Continuation],
    fid: str,
    fact: dict | None = None,
) -> Continuation {
    existing = nodes.get(fid, None);
    if existing is not None { return existing; }
    f = fact if fact is not None else {"id": fid};
    nd = Continuation(fid=fid, fact=f);
    root ++> nd;
    nodes[fid] = nd;
    return nd;
}

def _materialize_adj(adj: dict[str, list[str]]) -> dict[str, Continuation] {
    nodes: dict[str, Continuation] = {};
    for nid in adj.keys() {
        _ensure_continuation_node(nodes, nid);
    }
    for (src, kids) in adj.items() {
        for kid in kids {
            _ensure_continuation_node(nodes, kid);
        }
    }
    for (src, kids) in adj.items() {
        s = nodes.get(src, None);
        if s is None { continue; }
        for kid in kids {
            d = nodes.get(kid, None);
            if d is not None { s +>:ContinuesTo:+> d; }
        }
    }
    return nodes;
}

def _apply_continuation(
    pf: tuple,
    pr: tuple | None,
    fact: dict,
) -> tuple[tuple, tuple | None] {
    e = fact.get("edge", None);
    edge_name = e if e is not None else "then";
    if edge_name == "finally" {
        return (pf, pr);
    }
    if edge_name == "catch" {
        if pr is not None {
            rf = fact.get("result_f", None);
            rr = fact.get("result_r", None);
            out_f = tuple(rf) if rf is not None else pf;
            out_r = tuple(rr) if rr is not None else None;
            return (out_f, out_r);
        }
        return (pf, pr);
    }
    if pr is None {
        rf = fact.get("result_f", None);
        if rf is not None {
            rf_tuple = rf if isinstance(rf, tuple) else (rf,);
            return (rf_tuple, fact.get("result_r", None));
        }
        return (pf, pr);
    }
    rr = fact.get("result_r", None);
    if rr is not None {
        rf = fact.get("result_f", None);
        out_f = tuple(rf) if rf is not None else ();
        out_r = rr if isinstance(rr, tuple) else (rr,);
        return (out_f, out_r);
    }
    return (pf, pr);
}

def build_continuation_graph(facts: list[dict]) -> dict {
    adj: dict[str, list[str]] = {};
    parent: dict[str, str] = {};
    meta: dict[str, dict] = {};
    nodes: dict[str, Continuation] = {};
    for fact in facts {
        fid = fact["id"];
        meta[fid] = fact;
        if fid not in adj { adj[fid] = []; }
        _ensure_continuation_node(nodes, fid, fact);
    }
    for fact in facts {
        fid = fact["id"];
        pid = fact.get("parent", None);
        if pid {
            if pid not in adj { adj[pid] = []; }
            adj[pid].append(fid);
            parent[fid] = pid;
            _ensure_continuation_node(nodes, pid);
            p_ref = nodes.get(pid, None);
            c_ref = nodes.get(fid, None);
            if p_ref is not None and c_ref is not None { p_ref +>:ContinuesTo:+> c_ref; }
        }
    }
    for node_key in adj.keys() {
        adj[node_key] = sorted(adj[node_key]);
    }
    return {"adj": adj, "parent": parent, "meta": meta};
}

def reachable_continuations(`root: str, adj: dict[str, list[str]]) -> list[str] {
    nodes = _materialize_adj(adj);
    start = _ensure_continuation_node(nodes, `root);
    w = start spawn ReachWalker(adj=adj, nodes=nodes, claimed={}, order=[]);
    return w.order;
}

def propagate_continuation_tuples(
    `root: str,
    adj: dict[str, list[str]],
    meta: dict[str, dict],
) -> dict {
    out: dict = {};
    order = reachable_continuations(`root, adj);
    for fid in order {
        fact = meta[fid];
        if fid == `root {
            tf = fact.get("tuple_f", None);
            tr = fact.get("tuple_r", None);
            tf_t = tuple(tf) if tf is not None else ();
            tr_t = tuple(tr) if tr is not None else None;
            out[fid] = (tf_t, tr_t);
            continue;
        }
        par = fact["parent"];
        parent_pair = out[par];
        pf = parent_pair[0] as tuple;
        pr = parent_pair[1] as tuple | None;
        out[fid] = _apply_continuation(pf, pr, fact);
    }
    return out;
}

def flatten_admitted_thenables(
    adj: dict[str, list[str]],
    meta: dict[str, dict],
    admitted: set[str],
) -> tuple[dict[str, list[str]], list[str]] {
    new_adj: dict[str, list[str]] = {};
    for (node, children) in adj.items() {
        copied: list[str] = [];
        for c in children { copied.append(c); }
        new_adj[node] = copied;
    }
    flattened: list[str] = [];
    for fid in sorted(meta.keys()) {
        fact = meta[fid];
        if not fact.get("thenable", False) or fid not in admitted { continue; }
        flattened.append(fid);
        pid = fact.get("parent", None);
        if not pid { continue; }
        bridged: list[str] = [];
        for c in new_adj.get(pid, []) {
            if c != fid { bridged.append(c); }
        }
        for c in new_adj.get(fid, []) { bridged.append(c); }
        uniq: dict[str, bool] = {};
        merged: list[str] = [];
        for c in bridged {
            if c not in uniq {
                uniq[c] = True;
                merged.append(c);
            }
        }
        new_adj[pid] = sorted(merged);
    }
    return (new_adj, flattened);
}

def continuation_paths(`root: str, adj: dict[str, list[str]]) -> list[tuple[str, ...]] {
    nodes = _materialize_adj(adj);
    start = _ensure_continuation_node(nodes, `root);
    paths: list[list[str]] = [];
    start spawn PathBranch(adj=adj, nodes=nodes, trail=[], paths=paths);
    out: list[tuple[str, ...]] = [];
    for p in paths {
        out.append(tuple(p));
    }
    return sorted(out);
}

test "diamond revisit reachable order dedupes join" {
    adj = {"root": ["a", "b"], "a": ["join"], "b": ["join"], "join": []};
    assert reachable_continuations("root", adj) == ["root", "a", "b", "join"];;
    assert continuation_paths("root", adj) == [("root", "a", "join"), ("root", "b", "join")];;
}

test "unknown id tolerance for ghost roots and stub parents" {
    adj = {"a": ["b"], "b": []};
    assert reachable_continuations("ghost", adj) == ["ghost"];;
    assert continuation_paths("ghost", adj) == [("ghost",)];;
    facts = [{"id": "child", "parent": "missing_parent"}];
    g = build_continuation_graph(facts);
    assert g["adj"]["missing_parent"] == ["child"];;
    assert g["parent"]["child"] == "missing_parent";;
    assert reachable_continuations("missing_parent", g["adj"]) == ["missing_parent", "child"];;
}

test "cycle path snapshot skips revisit without disengage" {
    adj = {"a": ["b"], "b": ["c"], "c": ["a"]};
    assert continuation_paths("a", adj) == [("a", "b", "c", "a")];;
    assert reachable_continuations("a", adj) == ["a", "b", "c"];;
}

test "diamond path revisit enumerates shared target branches" {
    adj = {"x": ["y", "z"], "y": [], "z": ["y"]};
    assert continuation_paths("x", adj) == [("x", "y"), ("x", "z", "y")];;
    assert reachable_continuations("x", adj) == ["x", "y", "z"];;
}

test "propagate finally catch then tuple semantics" {
    facts = [
        {"id": "r", "tuple_f": [1], "tuple_r": (99,)},
        {"id": "ok", "parent": "r", "edge": "then", "result_r": (2,)},
        {"id": "fin", "parent": "ok", "edge": "finally"},
        {"id": "cat", "parent": "r", "edge": "catch", "result_f": [7], "result_r": [6]},
    ];
    g = build_continuation_graph(facts);
    prop = propagate_continuation_tuples("r", g["adj"], g["meta"]);
    assert prop["r"] == ((1,), (99,));;
    assert prop["cat"] == ((7,), (6,));;
    assert prop["ok"] == ((), (2,));;
    assert prop["fin"] == ((), (2,));;
}

test "flatten admitted thenable bridges children and preserves siblings" {
    facts = [
        {"id": "p", "thenable": False},
        {"id": "t", "parent": "p", "thenable": True},
        {"id": "c1", "parent": "t"},
        {"id": "c2", "parent": "t"},
        {"id": "sib", "parent": "p"},
    ];
    g = build_continuation_graph(facts);
    (na, flat) = flatten_admitted_thenables(g["adj"], g["meta"], {"t"});
    assert flat == ["t"];;
    assert na["p"] == ["c1", "c2", "sib"];;
}
