node Crate {
    has cid: str;
    has name: str;
    has version: str;
    has duration: float;
    has kind: str;
}
node BuildRoot {
    has rid: str;
}
edge Depends {}

walker CollectReachable {
    has claimed: dict[str, bool] = {};
    has found: list[Crate] = [];
    can collect with Crate entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here);
        for nxt in [here ->:Depends:->][?:Crate] {
            visit [nxt];
        }
        print("visited " + here.cid);
    }
}

walker CollectFromRoot {
    has claimed: dict[str, bool] = {};
    has found: list[Crate] = [];
    can step_root with BuildRoot entry {
        for nxt in [here ->:Depends:->][?:Crate] {
            visit [nxt];
        }
        print("root visited " + here.rid);
    }
    can step_crate with Crate entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here);
        for nxt in [here ->:Depends:->][?:Crate] {
            visit [nxt];
        }
        print("visited " + here.cid);
    }
}

def create_build_graph(rid: str) -> BuildRoot {
    g = BuildRoot(rid=rid);
    return g;
}

def register_crate(graph_root: BuildRoot, cid: str, name: str, version: str, duration: float, kind: str) -> Crate {
    nd = Crate(cid=cid, name=name, version=version, duration=duration, kind=kind);
    graph_root +>:Depends:+> nd;
    return nd;
}

def add_depends(src: Crate, dst: Crate) {
    src +>:Depends:+> dst;
}

def transitive_closure(start: Crate) -> list[str] {
    w = start spawn CollectReachable(claimed={}, found=[]);
    ids: list[str] = [];
    for c in w.found {
        ids.append(c.cid);
    }
    return sorted(ids);
}

def transitive_closure_by_id(graph_root: BuildRoot, cid: str) -> list[str] {
    w = graph_root spawn CollectFromRoot(claimed={}, found=[]);
    target: Crate | None = None;
    for c in w.found {
        if c.cid == cid {
            target = c;
        }
    }
    if target is None {
        return [];
    }
    t: Crate = target;
    return transitive_closure(t);
}

def slowest_units(graph_root: BuildRoot, top_n: int) -> list[str] {
    w = graph_root spawn CollectFromRoot(claimed={}, found=[]);
    remaining: list[Crate] = [];
    for c in w.found {
        remaining.append(c);
    }
    result: list[str] = [];
    count: int = 0;
    if top_n > len(remaining) {
        count = len(remaining);
    } else {
        count = top_n;
    }
    for _ in range(count) {
        best: Crate | None = None;
        best_idx: int = 0;
        idx: int = 0;
        for c in remaining {
            if best is None {
                best = c;
                best_idx = idx;
            } else {
                bv: Crate = best;
                if c.duration > bv.duration {
                    best = c;
                    best_idx = idx;
                }
            }
            idx += 1;
        }
        if best is not None {
            b: Crate = best;
            result.append(b.cid);
            nxt: list[Crate] = [];
            j: int = 0;
            for c2 in remaining {
                if j != best_idx {
                    nxt.append(c2);
                }
                j += 1;
            }
            remaining = nxt;
        }
    }
    return result;
}

with entry {
    demo = BuildRoot(rid="demo");
    root ++> demo;
    w = demo spawn CollectFromRoot(claimed={}, found=[]);
    print("demo deps " + str(len(w.found)));
}
