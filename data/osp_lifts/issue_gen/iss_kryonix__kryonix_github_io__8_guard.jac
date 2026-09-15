"""kryonix/kryonix.github.io#8 — recursive CTE-style relation expansion."""

node Entity {
    has cid: str;
    has depth: int = 0;
}

edge Rel {}

walker ExpandWalker {
    has claimed: dict[str, bool] = {};
    has max_depth: int = 0;
    has out: list[str] = [];
    has by_cid: dict[str, Entity] = {};

    can step with Entity entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.out.append(here.cid);
        print("expand", here.cid, here.depth);
        if here.depth >= self.max_depth {
            disengage;
        }
        raw: list[Entity] = [here ->:Rel:->][?:Entity];
        cids: list[str] = [];
        for kid in raw {
            cids.append(kid.cid);
        }
        cids = sorted(cids);
        pos: int = len(cids) - 1;
        while pos >= 0 {
            kcid = cids[pos];
            for kid in raw {
                if kid.cid == kcid {
                    if kcid not in self.claimed {
                        kid.depth = here.depth + 1;
                        visit :0: [kid];
                    }
                }
            }
            pos -= 1;
        }
    }
}

walker DepthWalker {
    has claimed: dict[str, bool] = {};
    has max_depth: int = 0;
    has depths: dict[str, int] = {};
    has by_cid: dict[str, Entity] = {};

    can measure with Entity entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid in self.depths {
            if here.depth < self.depths[here.cid] {
                self.depths[here.cid] = here.depth;
            }
        } else {
            self.depths[here.cid] = here.depth;
        }
        print("depth", here.cid, here.depth);
        if here.depth >= self.max_depth {
            disengage;
        }
        raw: list[Entity] = [here ->:Rel:->][?:Entity];
        cids: list[str] = [];
        for kid in raw {
            cids.append(kid.cid);
        }
        cids = sorted(cids);
        pos: int = len(cids) - 1;
        while pos >= 0 {
            kcid = cids[pos];
            for kid in raw {
                if kid.cid == kcid {
                    if kcid not in self.claimed {
                        kid.depth = here.depth + 1;
                        visit :0: [kid];
                    }
                }
            }
            pos -= 1;
        }
    }
}

def build_link(store: dict[str, Entity], src: str, dst: str) -> None {
    if src not in store {
        sn = Entity(cid=src);
        store[src] = sn;
        root ++> sn;
    }
    if dst not in store {
        dn = Entity(cid=dst);
        store[dst] = dn;
        root ++> dn;
    }
    store[src] +>:Rel:+> store[dst];
}

def recursive_closure(anchor_ids: list[str], edges: list[list[str]], max_depth: int) -> list[str] {
    store: dict[str, Entity] = {};
    for edge in edges {
        build_link(store, edge[0], edge[1]);
    }
    out: list[str] = [];
    claimed: dict[str, bool] = {};
    for aid in anchor_ids {
        if aid not in store {
            continue;
        }
        nd = store[aid];
        nd.depth = 0;
        w = nd spawn ExpandWalker(
            claimed=claimed,
            max_depth=max_depth,
            out=out,
            by_cid=store
        );
        print("closure_walk", aid, len(w.out));
    }
    return sorted(out);
}

def recursive_count(anchor_ids: list[str], edges: list[list[str]], max_depth: int) -> int {
    xs = recursive_closure(anchor_ids, edges, max_depth);
    return len(xs);
}

def recursive_depth_map(anchor_ids: list[str], edges: list[list[str]], max_depth: int) -> dict[str, int] {
    store: dict[str, Entity] = {};
    for edge in edges {
        build_link(store, edge[0], edge[1]);
    }
    depths: dict[str, int] = {};
    claimed: dict[str, bool] = {};
    for aid in anchor_ids {
        if aid not in store {
            continue;
        }
        nd = store[aid];
        nd.depth = 0;
        w = nd spawn DepthWalker(
            claimed=claimed,
            max_depth=max_depth,
            depths=depths,
            by_cid=store
        );
        print("depth_walk", aid, len(w.depths));
    }
    return depths;
}

def recursive_reachable(anchor_id: str, target_id: str, edges: list[list[str]], max_depth: int) -> bool {
    xs = recursive_closure([anchor_id], edges, max_depth);
    for x in xs {
        if x == target_id {
            return True;
        }
    }
    return False;
}

with entry {
    boot = Entity(cid="boot");
    root ++> boot;
    claimed: dict[str, bool] = {};
    out: list[str] = [];
    store: dict[str, Entity] = {};
    store["boot"] = boot;
    root spawn ExpandWalker(
        claimed=claimed,
        max_depth=0,
        out=out,
        by_cid=store
    );
    print("entry_boot", len(out));
}

test "diamond_adversarial_revisit" {
    edges: list[list[str]] = [["a", "b"], ["a", "c"], ["b", "d"], ["c", "d"], ["d", "b"]];
    got = recursive_closure(["a"], edges, 3);
    assert got == ["a", "b", "c", "d"];
    dm = recursive_depth_map(["a"], edges, 3);
    assert dm["d"] == 2;
}

test "unknown_anchor_tolerance" {
    edges: list[list[str]] = [["x", "y"], ["y", "z"]];
    got = recursive_closure(["missing", "x"], edges, 5);
    assert got == ["x", "y", "z"];
    assert recursive_reachable("missing", "z", edges, 5) == False;
}

test "cycle_claim_map_no_truncation" {
    edges: list[list[str]] = [["p", "q"], ["q", "p"], ["q", "r"]];
    got = recursive_closure(["p"], edges, 5);
    assert got == ["p", "q", "r"];
    assert recursive_count(["p"], edges, 5) == 3;
}

test "max_depth_zero_anchor_only" {
    edges: list[list[str]] = [["s", "t"], ["t", "u"]];
    got = recursive_closure(["s"], edges, 0);
    assert got == ["s"];
    assert recursive_reachable("s", "t", edges, 0) == False;
}

test "multi_anchor_shared_frontier" {
    edges: list[list[str]] = [["a", "m"], ["b", "m"], ["m", "c"]];
    got = recursive_closure(["a", "b"], edges, 2);
    assert got == ["a", "b", "c", "m"];
}
