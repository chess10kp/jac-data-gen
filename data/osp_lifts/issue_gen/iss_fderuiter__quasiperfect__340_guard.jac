"""Training lift source: fderuiter/quasiperfect#340."""

node Comp {
    has idx: int;
    has p: int;
    has two_e: int;
}

edge Implies {}

node Cdg {
    has forced_candidates: list[list[int]];
    has adjacency: list[list[int]];
    has scc_id: list[int];
    has scc_members: list[list[int]];
}

def divisors_gt_one(two_e_plus_one: int) -> list[int] {
    out: list[int] = [];
    d: int = 2;
    while d < two_e_plus_one {
        if two_e_plus_one % d == 0 {
            out.append(d);
        }
        d += 1;
    }
    return sorted(out);
}

def prime_to_component_indices(comps: list[Comp]) -> dict[int, list[int]] {
    mp: dict[int, list[int]] = {};
    for c in comps {
        if c.p in mp {
            bucket: list[int] = mp[c.p];
        } else {
            bucket = [];
        }
        bucket.append(c.idx);
        mp[c.p] = bucket;
    }
    return mp;
}

def forced_candidate_sets(comps: list[Comp]) -> list[list[int]] {
    n: int = len(comps);
    out: list[list[int]] = [];
    i: int = 0;
    while i < n {
        out.append([]);
        i += 1;
    }
    for ci in comps {
        modn: int = ci.two_e + 1;
        divs: list[int] = divisors_gt_one(modn);
        for d in divs {
            for cj in comps {
                if cj.p % d == 1 {
                    row: list[int] = out[ci.idx];
                    seen: bool = False;
                    for v in row {
                        if v == cj.idx {
                            seen = True;
                        }
                    }
                    if not seen {
                        row.append(cj.idx);
                    }
                    out[ci.idx] = sorted(row);
                }
            }
        }
    }
    return out;
}

def implication_adjacency(forced: list[list[int]], n: int) -> list[list[int]] {
    adj: list[list[int]] = [];
    i: int = 0;
    while i < n {
        adj.append([]);
        i += 1;
    }
    i = 0;
    while i < n {
        for j in forced[i] {
            adj[i].append(j);
        }
        i += 1;
    }
    return adj;
}

def tarjan_scc(adj: list[list[int]]) -> list[any] {
    n: int = len(adj);
    index: int = 0;
    stack: list[int] = [];
    onstack: dict[int, bool] = {};
    ids: list[int] = [];
    low: list[int] = [];
    scc_id: list[int] = [];
    i: int = 0;
    while i < n {
        ids.append(-1);
        low.append(0);
        scc_id.append(-1);
        i += 1;
    }
    members: list[list[int]] = [];
    work: list[list[int]] = [];
    for start in range(n) {
        if ids[start] != -1 {
            continue;
        }
        work.append([start, 0]);
        while len(work) > 0 {
            frame: list[int] = work[len(work) - 1];
            v: int = frame[0];
            ei: int = frame[1];
            if ei == 0 {
                ids[v] = index;
                low[v] = index;
                index += 1;
                stack.append(v);
                onstack[v] = True;
            }
            if ei < len(adj[v]) {
                w: int = adj[v][ei];
                frame[1] = ei + 1;
                if ids[w] == -1 {
                    work.append([w, 0]);
                } elif w in onstack {
                    if low[w] < low[v] {
                        low[v] = low[w];
                    }
                }
            } else {
                work.pop();
                if low[v] == ids[v] {
                    comp: list[int] = [];
                    while True {
                        x: int = stack[len(stack) - 1];
                        stack.pop();
                        onstack[x] = False;
                        scc_id[x] = len(members);
                        comp.append(x);
                        if x == v {
                            break;
                        }
                    }
                    members.append(sorted(comp));
                }
                if len(work) > 0 {
                    parent: list[int] = work[len(work) - 1];
                    pv: int = parent[0];
                    if low[v] < low[pv] {
                        low[pv] = low[v];
                    }
                }
            }
        }
    }
    return [scc_id, members];
}

def wire_implication_graph(comps: list[Comp], adj: list[list[int]]) {
    by_idx: dict[int, Comp] = {};
    for c in comps {
        by_idx[c.idx] = c;
        root ++> c;
    }
    i: int = 0;
    while i < len(adj) {
        src: Comp = by_idx[i];
        for j in adj[i] {
            dst: Comp = by_idx[j];
            src +>:Implies:+> dst;
        }
        i += 1;
    }
}

walker ImplicationWalk {
    has claimed: dict[int, bool] = {};
    has order: list[int] = {};

    can step with Comp entry {
        if here.idx in self.claimed {
            skip;
        }
        self.claimed[here.idx] = True;
        self.order.append(here.idx);
        print(here.idx);
        kids: list[Comp] = [here ->:Implies:->][?:Comp];
        nxt: list[Comp] = [];
        for ch in kids {
            nxt.append(ch);
        }
        visit :0: nxt else { disengage; }
    }
}

def make_cdg(comps: list[Comp]) -> Cdg {
    forced: list[list[int]] = forced_candidate_sets(comps);
    n: int = len(comps);
    adj: list[list[int]] = implication_adjacency(forced, n);
    scc_pair: list[any] = tarjan_scc(adj);
    scc_ids: list[int] = scc_pair[0];
    scc_members: list[list[int]] = scc_pair[1];
    wire_implication_graph(comps, adj);
    w = root spawn ImplicationWalk(claimed={});
    print(len(w.order));
    return Cdg(
        forced_candidates=forced,
        adjacency=adj,
        scc_id=scc_ids,
        scc_members=scc_members
    );
}

test "divisors_gt_one_twelve" {
    xs: list[int] = divisors_gt_one(12);
    assert xs == [2, 3, 4, 6];
}

test "tarjan_chain_three" {
    adj: list[list[int]] = [[1], [2], []];
    pair: list[any] = tarjan_scc(adj);
    scc_ids: list[int] = pair[0];
    scc_members: list[list[int]] = pair[1];
    assert scc_ids == [2, 1, 0];
    assert scc_members == [[0], [1], [2]];
}

test "tarjan_mutual_cycle" {
    adj: list[list[int]] = [[1], [0]];
    pair: list[any] = tarjan_scc(adj);
    scc_ids: list[int] = pair[0];
    scc_members: list[list[int]] = pair[1];
    assert scc_ids == [0, 0];
    assert scc_members == [[0, 1]];
}

test "forced_candidate_mod_four" {
    c0 = Comp(idx=0, p=3, two_e=3);
    c1 = Comp(idx=1, p=5, two_e=0);
    c2 = Comp(idx=2, p=7, two_e=0);
    comps: list[Comp] = [c0, c1, c2];
    forced: list[list[int]] = forced_candidate_sets(comps);
    assert forced[0] == [1, 2];
    assert forced[1] == [];
    assert forced[2] == [];
}

test "make_cdg_scc_and_adjacency" {
    c0 = Comp(idx=0, p=3, two_e=3);
    c1 = Comp(idx=1, p=5, two_e=0);
    c2 = Comp(idx=2, p=7, two_e=0);
    comps: list[Comp] = [c0, c1, c2];
    cdg: Cdg = make_cdg(comps);
    assert cdg.adjacency == [[1, 2], [], []];
    assert cdg.scc_id == [2, 0, 1];
    assert cdg.scc_members == [[1], [2], [0]];
}
