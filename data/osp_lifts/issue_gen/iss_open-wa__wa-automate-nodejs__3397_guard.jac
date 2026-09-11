"""open-wa/wa-automate-nodejs#3397 release readiness topology audit."""

node Package {
    has id: str;
    has version: str = "5.0.0-alpha.7";
    has in_fixed: bool = False;
    has prerelease: bool = True;
}

edge DependsOn {}

def build_dep_graph(package_ids: list[str], edges: list[list[str]]) -> dict[str, list[str]] {
    graph: dict[str, list[str]] = {};
    for pid in package_ids {
        graph[pid] = [];
    }
    for edge in edges {
        parent_id = edge[0];
        child_id = edge[1];
        if parent_id in graph {
            graph[parent_id].append(child_id);
        }
    }
    for pid in package_ids {
        graph[pid] = sorted(graph[pid]);
    }
    return graph;
}

def missing_from_fixed_group(all_ids: list[str], fixed_ids: list[str]) -> list[str] {
    fixed: dict[str, bool] = {};
    for fid in fixed_ids {
        fixed[fid] = True;
    }
    missing: list[str] = [];
    for pid in sorted(all_ids) {
        if pid not in fixed {
            missing.append(pid);
        }
    }
    return missing;
}

def wire_packages(package_ids: list[str], deps: list[list[str]]) -> dict[str, Package] {
    store: dict[str, Package] = {};
    for pid in package_ids {
        nd = Package(id=pid);
        root ++> nd;
        store[pid] = nd;
    }
    for pair in deps {
        parent_id = pair[0];
        child_id = pair[1];
        if parent_id in store and child_id in store {
            parent_nd = store[parent_id];
            child_nd = store[child_id];
            parent_nd +>: DependsOn:+> child_nd;
        }
    }
    return store;
}

walker DepWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has graph: dict[str, list[str]] = {};
    has store: dict[str, Package] = {};

    can traverse_pkg with Package entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        self.found.append(here.id);
        next_ids: list[str] = [];
        if here.id in self.graph {
            for dep_id in self.graph[here.id] {
                next_ids.append(dep_id);
            }
        }
        visit_list: list[Package] = [];
        for nid in next_ids {
            if nid in self.store {
                visit_list.append(self.store[nid]);
            }
        }
        if visit_list {
            visit :0: visit_list;
        } else {
            disengage;
        }
        print("dep: " + here.id);
    }
}

def transitive_dependencies(root_id: str, graph: dict[str, list[str]], store: dict[str, Package]) -> list[str] {
    if root_id not in store {
        return [];
    }
    start = store[root_id];
    w = start spawn DepWalker(claimed={}, graph=graph, store=store);
    return sorted(w.found);
}

def publish_blockers(package_meta: dict[str, dict[str, bool]], fixed_ids: list[str]) -> list[str] {
    fixed: dict[str, bool] = {};
    for fid in fixed_ids {
        fixed[fid] = True;
    }
    blockers: list[str] = [];
    keys: list[str] = [];
    for k in package_meta {
        keys.append(k);
    }
    for pid in sorted(keys) {
        if pid not in fixed {
            blockers.append(pid);
        } else {
            meta = package_meta[pid];
            prerelease = True;
            qualified = False;
            if "prerelease" in meta {
                prerelease = meta["prerelease"];
            }
            if "qualified" in meta {
                qualified = meta["qualified"];
            }
            if prerelease or not qualified {
                blockers.append(pid);
            }
        }
    }
    return blockers;
}

def kahn_order(nodes: list[str], graph: dict[str, list[str]]) -> list[str] {
    indegree: dict[str, int] = {};
    for n in nodes {
        indegree[n] = 0;
    }
    for n in nodes {
        if n in graph {
            for ch in graph[n] {
                if ch in indegree {
                    indegree[ch] = indegree[ch] + 1;
                }
            }
        }
    }
    queue: list[str] = [];
    for n in sorted(nodes) {
        if indegree[n] == 0 {
            queue.append(n);
        }
    }
    order: list[str] = [];
    while queue {
        cur = queue[0];
        rest: list[str] = [];
        idx = 1;
        while idx < len(queue) {
            rest.append(queue[idx]);
            idx = idx + 1;
        }
        queue = rest;
        order.append(cur);
        if cur in graph {
            for ch in graph[cur] {
                if ch in indegree {
                    indegree[ch] = indegree[ch] - 1;
                    if indegree[ch] == 0 {
                        queue.append(ch);
                    }
                }
            }
        }
    }
    if len(order) != len(nodes) {
        return [];
    }
    return order;
}

with entry {
    demo_ids: list[str] = ["wa-automate", "runtime-core", "runtime-node"];
    demo_deps: list[list[str]] = [
        ["wa-automate", "runtime-core"],
        ["wa-automate", "runtime-node"],
        ["runtime-node", "runtime-core"]
    ];
    demo_store = wire_packages(demo_ids, demo_deps);
    demo_graph = build_dep_graph(demo_ids, demo_deps);
    demo_w = demo_store["wa-automate"] spawn DepWalker(claimed={}, graph=demo_graph, store=demo_store);
    print("audit: " + demo_w.found[0]);
}

test "diamond_revisit_transitive_deps" {
    ids: list[str] = ["A", "B", "C", "D"];
    deps: list[list[str]] = [["A", "C"], ["A", "B"], ["C", "D"], ["B", "D"]];
    store = wire_packages(ids, deps);
    graph = build_dep_graph(ids, deps);
    got = transitive_dependencies("A", graph, store);
    assert got == ["A", "B", "C", "D"];;
}

test "unknown_root_transitive_deps" {
    graph: dict[str, list[str]] = {"orphan": []};
    store: dict[str, Package] = {};
    got = transitive_dependencies("missing-pkg", graph, store);
    assert got == [];;
}

test "missing_runtime_packages_from_fixed_group" {
    all_ids: list[str] = [
        "wa-automate",
        "runtime-browser",
        "runtime-bun",
        "runtime-core",
        "runtime-edge",
        "runtime-node"
    ];
    fixed: list[str] = ["wa-automate"];
    got = missing_from_fixed_group(all_ids, fixed);
    assert got == [
        "runtime-browser",
        "runtime-bun",
        "runtime-core",
        "runtime-edge",
        "runtime-node"
    ];;
}

test "publish_blockers_prerelease_and_unfixed" {
    meta: dict[str, dict[str, bool]] = {};
    ok_pkg: dict[str, bool] = {};
    ok_pkg["prerelease"] = False;
    ok_pkg["qualified"] = True;
    meta["wa-automate"] = ok_pkg;
    bad_pkg: dict[str, bool] = {};
    bad_pkg["prerelease"] = True;
    bad_pkg["qualified"] = False;
    meta["runtime-core"] = bad_pkg;
    unfixed_pkg: dict[str, bool] = {};
    unfixed_pkg["prerelease"] = False;
    unfixed_pkg["qualified"] = True;
    meta["runtime-browser"] = unfixed_pkg;
    fixed: list[str] = ["wa-automate", "runtime-core"];
    got = publish_blockers(meta, fixed);
    assert got == ["runtime-browser", "runtime-core"];;
}

test "kahn_cycle_returns_empty" {
    nodes: list[str] = ["publish", "qualify"];
    graph: dict[str, list[str]] = {"publish": ["qualify"], "qualify": ["publish"]};
    got = kahn_order(nodes, graph);
    assert got == [];;
}

test "kahn_diamond_publish_order" {
    nodes: list[str] = ["root", "left", "right", "leaf"];
    graph: dict[str, list[str]] = {
        "root": ["right", "left"],
        "left": ["leaf"],
        "right": ["leaf"],
        "leaf": []
    };
    got = kahn_order(nodes, graph);
    assert got == ["root", "left", "right", "leaf"];;
}
