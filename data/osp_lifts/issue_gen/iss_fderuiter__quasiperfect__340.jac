"""fderuiter/quasiperfect#340 — implication graph + SCC lift."""

node Component {
    has cid: str;
    has p: int;
    has two_e: int;
}

edge Implies {}

def divisors_gt1(n: int) -> list[int] {
    ds: list[int] = [];
    if n < 2 {
        return ds;
    }
    for d in range(2, n + 1) {
        if n % d == 0 {
            ds.append(d);
        }
    }
    return ds;
}

def sort_components_by_cid(nodes: list[Component]) -> list[Component] {
    out: list[Component] = [];
    for nd in nodes {
        out.append(nd);
    }
    for i in range(len(out)) {
        for j in range(i + 1, len(out)) {
            if out[i].cid > out[j].cid {
                tmp = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
        }
    }
    return out;
}

def forced_candidate_sets(specs: list[dict]) -> list[list[int]] {
    n: int = len(specs);
    forced: list[list[int]] = [];
    for _i in range(n) {
        forced.append([]);
    }
    if n == 0 {
        return forced;
    }
    prime_to_ix: dict[int, list[int]] = {};
    for i in range(n) {
        sp = specs[i] as dict;
        p: int = sp["p"];
        if p in prime_to_ix {
            prime_to_ix[p].append(i);
        } else {
            prime_to_ix[p] = [i];
        }
    }
    for i in range(n) {
        sp_i = specs[i] as dict;
        modulus: int = sp_i["two_e"] + 1;
        divs: list[int] = divisors_gt1(modulus);
        seen_j: dict[int, bool] = {};
        for d in divs {
            for j in range(n) {
                if j == i {
                    continue;
                }
                sp_j = specs[j] as dict;
                if sp_j["p"] % d == 1 {
                    if j not in seen_j {
                        seen_j[j] = True;
                        forced[i].append(j);
                    }
                }
            }
        }
        forced[i] = sorted(forced[i]);
    }
    return forced;
}

def implication_adjacency(forced: list[list[int]]) -> list[list[int]] {
    adj: list[list[int]] = [];
    for row in forced {
        adj.append([]);
        for j in row {
            adj[len(adj) - 1].append(j);
        }
    }
    return adj;
}

def tarjan_scc(adj: list[list[int]]) -> dict {
    n: int = len(adj);
    comp_to_scc: list[int] = [];
    for _k in range(n) {
        comp_to_scc.append(-1);
    }
    scc_members: list[list[int]] = [];
    if n == 0 {
        return {"forced_key": 0, "component_to_scc": comp_to_scc, "scc_members": scc_members};
    }
    order: list[int] = [];
    seen: list[bool] = [];
    for _k in range(n) {
        seen.append(False);
    }
    for start in range(n) {
        if seen[start] {
            continue;
        }
        stack: list[tuple] = [(start, 0)];
        while len(stack) > 0 {
            v: int = stack[len(stack) - 1][0];
            ei: int = stack[len(stack) - 1][1];
            if not seen[v] {
                seen[v] = True;
            }
            if ei < len(adj[v]) {
                u: int = adj[v][ei];
                stack[len(stack) - 1] = (v, ei + 1);
                if not seen[u] {
                    stack.append((u, 0));
                }
            } else {
                order.append(v);
                stack.pop();
            }
        }
    }
    rev: list[list[int]] = [];
    for _i in range(n) {
        rev.append([]);
    }
    for i in range(n) {
        for j in adj[i] {
            rev[j].append(i);
        }
    }
    seen2: list[bool] = [];
    for _k in range(n) {
        seen2.append(False);
    }
    sid: int = 0;
    for oi in range(len(order) - 1, -1, -1) {
        v = order[oi];
        if seen2[v] {
            continue;
        }
        memb: list[int] = [];
        stack2: list[int] = [v];
        seen2[v] = True;
        while len(stack2) > 0 {
            x: int = stack2[len(stack2) - 1];
            stack2.pop();
            memb.append(x);
            for u in rev[x] {
                if not seen2[u] {
                    seen2[u] = True;
                    stack2.append(u);
                }
            }
        }
        memb = sorted(memb);
        scc_members.append(memb);
        for m in memb {
            comp_to_scc[m] = sid;
        }
        sid += 1;
    }
    scc_members = sorted(scc_members);
    remap: dict[int, int] = {};
    for ni in range(len(scc_members)) {
        remap[comp_to_scc[scc_members[ni][0]]] = ni;
    }
    for vi in range(n) {
        comp_to_scc[vi] = remap[comp_to_scc[vi]];
    }
    return {"component_to_scc": comp_to_scc, "scc_members": scc_members};
}

def cdg_new(specs: list[dict]) -> dict {
    forced: list[list[int]] = forced_candidate_sets(specs);
    adj: list[list[int]] = implication_adjacency(forced);
    scc: dict = tarjan_scc(adj);
    return {
        "forced": forced,
        "adjacency": adj,
        "component_to_scc": scc["component_to_scc"],
        "scc_members": scc["scc_members"],
    };
}

def build_implication_graph(specs: list[dict]) -> Component {
    nodes: list[Component] = [];
    for i in range(len(specs)) {
        sp = specs[i] as dict;
        nd = Component(cid=str(i), p=sp["p"], two_e=sp["two_e"]);
        root ++> nd;
        nodes.append(nd);
    }
    if len(nodes) == 0 {
        return Component(cid="-1", p=0, two_e=0);
    }
    adj: list[list[int]] = implication_adjacency(forced_candidate_sets(specs));
    for i in range(len(adj)) {
        for j in adj[i] {
            if j >= 0 and j < len(nodes) {
                nodes[i] +>:Implies:+> nodes[j];
            }
        }
    }
    return nodes[0];
}

walker TraceImplies {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Component entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(["trace", here.cid]);
        kids: list[Component] = [];
        for ch in [here ->:Implies:->][?:Component] {
            kids.append(ch);
        }
        kids = sort_components_by_cid(kids);
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

with entry {
    demo_specs: list[dict] = [
        {"p": 13, "two_e": 4},
        {"p": 11, "two_e": 2},
        {"p": 31, "two_e": 6},
    ];
    print(cdg_new(demo_specs));
    graph_root_node = build_implication_graph(demo_specs);
    wk = graph_root_node spawn TraceImplies(claimed={});
    print(wk.found);
}
