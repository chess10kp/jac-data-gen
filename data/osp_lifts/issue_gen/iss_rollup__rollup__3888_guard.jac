"""rollup/rollup#3888 — module execution order for shared chunks."""

glob root;

node Module {
    has mid: str;
    has import_seq: list[str] = [];
}

edge Import {}

node ModuleGraph {
    has modules: dict[str, Module] = {};
}

walker ExecOrderWalker {
    has graph: ModuleGraph;
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Module entry {
        if here.mid in self.claimed {
            skip;
        }
        self.claimed[here.mid] = True;
        for dep_id in here.import_seq {
            if dep_id in self.graph.modules {
                kid = self.graph.modules[dep_id];
                visit :0: kid;
            }
        }
        self.order.append(here.mid);
        print([here.mid, self.order]);
    }
}

walker BootstrapWalker {
    can boot entry {
        specs: list[dict] = [
            {"mid": "lib1", "imports": []},
            {"mid": "main", "imports": ["lib1"]}
        ];
        g = build_graph(specs);
        ord = execution_order(g, "main");
        print(ord);
    }
}

def build_graph(specs: list[dict]) -> ModuleGraph {
    g = ModuleGraph();
    for spec in specs {
        mid = spec["mid"] as str;
        m = Module(mid=mid);
        g.modules[mid] = m;
        root ++> m;
    }
    for spec in specs {
        mid = spec["mid"] as str;
        imps: list[str] = [];
        if "imports" in spec {
            imps = spec["imports"] as list[str];
        }
        src = g.modules[mid];
        src.import_seq = imps;
        for dep_id in imps {
            if dep_id in g.modules {
                dst = g.modules[dep_id];
                src +>:Import:+> dst;
            }
        }
    }
    return g;
}

def execution_order(graph: ModuleGraph, entry_id: str) -> list[str] {
    if entry_id not in graph.modules {
        return [];
    }
    entry_node = graph.modules[entry_id];
    claimed: dict[str, bool] = {};
    order: list[str] = [];
    w = entry_node spawn ExecOrderWalker(
        graph=graph, claimed=claimed, order=order
    );
    return w.order;
}

def shared_order_conflict(graph: ModuleGraph, entry_ids: list[str]) -> bool {
    orders: list[list[str]] = [];
    for eid in entry_ids {
        orders.append(execution_order(graph, eid));
    }
    if len(orders) < 2 {
        return False;
    }
    shared: dict[str, bool] = {};
    for mid in orders[0] {
        shared[mid] = True;
    }
    for idx in range(1, len(orders)) {
        cur: dict[str, bool] = {};
        for mid in orders[idx] {
            cur[mid] = True;
        }
        nxt: dict[str, bool] = {};
        for mid in shared {
            if mid in cur {
                nxt[mid] = True;
            }
        }
        shared = nxt;
    }
    shared_ids: list[str] = [];
    for mid in shared {
        shared_ids.append(mid);
    }
    shared_ids = sorted(shared_ids);
    for i in range(len(shared_ids)) {
        for j in range(i + 1, len(shared_ids)) {
            a = shared_ids[i];
            b = shared_ids[j];
            ab_first = True;
            ab_set = False;
            for ord_list in orders {
                pos_a = -1;
                pos_b = -1;
                for k in range(len(ord_list)) {
                    if ord_list[k] == a {
                        pos_a = k;
                    }
                    if ord_list[k] == b {
                        pos_b = k;
                    }
                }
                if pos_a >= 0 and pos_b >= 0 {
                    if not ab_set {
                        ab_first = pos_a < pos_b;
                        ab_set = True;
                    } elif (pos_a < pos_b) != ab_first {
                        return True;
                    }
                }
            }
        }
    }
    return False;
}

with entry {
    root spawn BootstrapWalker();
}

test "execution_order_deps_before_entry" {
    specs: list[dict] = [
        {"mid": "lib1", "imports": []},
        {"mid": "main", "imports": ["lib1"]}
    ];
    g = build_graph(specs);
    ord = execution_order(g, "main");
    assert ord == ["lib1", "main"];
}

test "execution_order_unknown_entry_empty" {
    specs: list[dict] = [
        {"mid": "only", "imports": []}
    ];
    g = build_graph(specs);
    ord = execution_order(g, "missing");
    assert ord == [];
}

test "shared_order_conflict_single_entry_false" {
    specs: list[dict] = [
        {"mid": "a", "imports": []},
        {"mid": "b", "imports": ["a"]}
    ];
    g = build_graph(specs);
    assert shared_order_conflict(g, ["b"]) == False;
}

test "shared_order_conflict_consistent_pair_false" {
    specs: list[dict] = [
        {"mid": "a", "imports": []},
        {"mid": "b", "imports": ["a"]},
        {"mid": "c", "imports": ["a", "b"]}
    ];
    g = build_graph(specs);
    assert shared_order_conflict(g, ["b", "c"]) == False;
}

test "shared_order_conflict_opposite_relative_order_true" {
    specs: list[dict] = [
        {"mid": "shared", "imports": []},
        {"mid": "left", "imports": ["shared"]},
        {"mid": "right", "imports": ["shared"]},
        {"mid": "e1", "imports": ["left", "right"]},
        {"mid": "e2", "imports": ["right", "left"]}
    ];
    g = build_graph(specs);
    o1 = execution_order(g, "e1");
    o2 = execution_order(g, "e2");
    assert "left" in o1;
    assert "right" in o2;
    assert shared_order_conflict(g, ["e1", "e2"]) == True;
}

test "build_graph_registers_all_modules" {
    specs: list[dict] = [
        {"mid": "x", "imports": []},
        {"mid": "y", "imports": ["x"]}
    ];
    g = build_graph(specs);
    assert "x" in g.modules;
    assert "y" in g.modules;
    assert g.modules["y"].import_seq == ["x"];
}
