"""
NixOS/nix#6361 — recursive flake dependency resolution with trace.
Mirrors meta-repo resolve loops where missing cycle guards yield stack overflow
and no usable --show-trace output.
"""

node Repo {
    has cid: str;
    has name: str;
}

edge Depends {}

node GraphHub {
    has nodes: dict[str, Repo] = {};
}

walker TraceResolve {
    has claimed: dict[str, bool] = {};
    has on_path: dict[str, bool] = {};
    has show_trace: bool = True;
    has trace: list[str] = [];
    has order: list[str] = [];
    has status: str = "ok";
    has depth: int = 0;
    has depth_limit: int = 64;

    can step with Repo entry {
        if here.cid in self.on_path {
            if self.show_trace {
                self.trace.append(here.cid);
            }
            self.status = "cycle";
            skip;
        }
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.on_path[here.cid] = True;
        self.depth += 1;
        self.order.append(here.cid);
        if self.show_trace {
            self.trace.append(here.cid);
        }
        if self.depth > self.depth_limit {
            self.status = "overflow";
            print("overflow", here.cid, self.depth);
        } else {
            kids: list[Repo] = [];
            for ch in [here ->:Depends:->][?:Repo] {
                kids.append(ch);
            }
            kids = sorted(kids, key=lambda x: x.cid);
            if kids {
                visit :0: kids;
            }
        }
        self.on_path[here.cid] = False;
    }
}

def make_repo_graph(edges: dict[str, list[str]]) -> GraphHub {
    hub = GraphHub();
    root ++> hub;
    keys: list[str] = [];
    for k in edges {
        keys.append(k);
    }
    keys = sorted(keys);
    for cid in keys {
        nd = Repo(cid=cid, name=cid);
        hub.nodes[cid] = nd;
        root ++> nd;
    }
    pair_keys: list[str] = [];
    for src in edges {
        dst_list = edges[src];
        for dst in dst_list {
            pair_keys.append(src + "\t" + dst);
        }
    }
    pair_keys = sorted(pair_keys);
    for pk in pair_keys {
        parts: list[str] = pk.split("\t");
        src_id = parts[0];
        dst_id = parts[1];
        a = hub.nodes[src_id];
        b = hub.nodes[dst_id];
        a +>:Depends:+> b;
    }
    return hub;
}

def resolve_with_trace(
    hub: GraphHub,
    root_id: str,
    show_trace: bool = True,
    depth_limit: int = 64
) -> dict {
    empty_trace: list[str] = [];
    empty_order: list[str] = [];
    if root_id not in hub.nodes {
        result: dict = {};
        result["status"] = "unknown";
        result["trace"] = empty_trace;
        result["order"] = empty_order;
        return result;
    }
    nd = hub.nodes[root_id];
    w = nd spawn TraceResolve(show_trace=show_trace, depth_limit=depth_limit);
    print("resolve", root_id, w.status, len(w.order));
    out: dict = {};
    out["status"] = w.status;
    out["trace"] = w.trace;
    out["order"] = w.order;
    return out;
}

def format_trace(trace: list[str]) -> str {
    if len(trace) == 0 {
        return "";
    }
    s = trace[0];
    for i in range(1, len(trace)) {
        s = s + " -> " + trace[i];
    }
    return s;
}

test "unknown_root" {
    hub = make_repo_graph({});
    r = resolve_with_trace(hub, "missing");
    assert r["status"] == "unknown";;
    assert r["trace"] == [];;
    assert r["order"] == [];;
}

test "linear_resolve" {
    edges: dict[str, list[str]] = {};
    edges["a"] = ["b"];
    edges["b"] = ["c"];
    hub = make_repo_graph(edges);
    r = resolve_with_trace(hub, "a", show_trace=True, depth_limit=64);
    assert r["status"] == "ok";;
    assert r["order"] == ["a", "b", "c"];;
    assert r["trace"] == ["a", "b", "c"];;
}

test "cycle_detect" {
    edges: dict[str, list[str]] = {};
    edges["a"] = ["b"];
    edges["b"] = ["c"];
    edges["c"] = ["a"];
    hub = make_repo_graph(edges);
    r = resolve_with_trace(hub, "a");
    assert r["status"] == "cycle";;
    assert r["order"] == ["a", "b", "c"];;
    assert r["trace"] == ["a", "b", "c", "a"];;
}

test "diamond_dag_ok" {
    edges: dict[str, list[str]] = {};
    edges["a"] = ["b", "c"];
    edges["b"] = ["d"];
    edges["c"] = ["d"];
    hub = make_repo_graph(edges);
    r = resolve_with_trace(hub, "a");
    assert r["status"] == "ok";;
    assert r["order"] == ["a", "b", "c", "d"];;
}

test "depth_overflow" {
    edges: dict[str, list[str]] = {};
    edges["a"] = ["b"];
    edges["b"] = ["c"];
    edges["c"] = ["d"];
    hub = make_repo_graph(edges);
    r = resolve_with_trace(hub, "a", show_trace=False, depth_limit=2);
    assert r["status"] == "overflow";;
    assert r["order"] == ["a", "b", "c"];;
    assert r["trace"] == [];;
}

test "format_trace_join" {
    assert format_trace([]) == "";;
    assert format_trace(["x", "y"]) == "x -> y";;
}
